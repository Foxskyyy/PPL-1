package utils

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"net/smtp"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v4"
	"github.com/lestrrat-go/jwx/v2/jwk"
	"golang.org/x/crypto/bcrypt"

	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
)

const otpChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

type Claims struct {
	UserID uint `json:"user_id"`
	jwt.RegisteredClaims
}

func getSecretKey() []byte {
	key := os.Getenv("JWT_SECRET")
	if key == "" {
		panic("JWT_SECRET not set")
	}
	return []byte(key)
}

func ValidateAppleToken(token string) (map[string]interface{}, error) {
	set, err := jwk.Fetch(context.Background(), "https://appleid.apple.com/auth/keys")
	if err != nil {
		return nil, fmt.Errorf("failed to fetch Apple keys: %w", err)
	}

	parsedToken, err := jwt.Parse(token, func(t *jwt.Token) (interface{}, error) {
		kid, ok := t.Header["kid"].(string)
		if !ok {
			return nil, errors.New("missing kid in header")
		}
		key, found := set.LookupKeyID(kid)
		if !found {
			return nil, fmt.Errorf("unable to find key with kid: %s", kid)
		}
		var rawKey interface{}
		if err := key.Raw(&rawKey); err != nil {
			return nil, fmt.Errorf("failed to get raw key: %w", err)
		}
		return rawKey, nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}

	claims, ok := parsedToken.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	if claims["iss"] != "https://appleid.apple.com" {
		return nil, errors.New("invalid issuer")
	}

	clientID := config.GetEnv("APPLE_CLIENT_ID", "")
	if claims["aud"] != clientID {
		return nil, errors.New("invalid audience")
	}

	return claims, nil
}

func GenerateToken(userID uint) (string, string, error) {
	secretKey := getSecretKey()

	accessTokenClaims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
		},
	}
	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessTokenClaims)
	accessTokenString, err := accessToken.SignedString(secretKey)
	if err != nil {
		return "", "", err
	}

	refreshTokenClaims := &Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
		},
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshTokenClaims)
	refreshTokenString, err := refreshToken.SignedString(secretKey)
	if err != nil {
		return "", "", err
	}

	return accessTokenString, refreshTokenString, nil
}

func ValidateToken(tokenString string) (*Claims, error) {
	secretKey := getSecretKey()

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return secretKey, nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return claims, nil
}

func AuthenticateUser(email string, password string) (*models.User, error) {
	var user models.User
	result := config.DB.Where("email = ?", email).First(&user)
	if result.Error != nil {
		return nil, errors.New("invalid email or password")
	}

	err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, errors.New("invalid email or password")
	}

	return &user, nil
}

func HashPassword(password string) (string, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hashedPassword), nil
}

func GenerateOTP() (string, error) {
	otpLength := 6
	otp := make([]byte, otpLength)

	for i := range otp {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(otpChars))))
		if err != nil {
			return "", err
		}
		otp[i] = otpChars[n.Int64()]
	}

	return string(otp), nil
}

func SendVerificationEmail(email, token string) error {
	var user models.User
	result := config.DB.Where("email = ?", email).First(&user)
	if result.Error != nil {
		return result.Error
	}

	from := os.Getenv("SMTP_EMAIL")
	password := os.Getenv("SMTP_PASSWORD")
	if from == "" || password == "" {
		return errors.New("SMTP credentials are not set")
	}

	to := []string{email}
	smtpHost := "smtp.gmail.com"
	smtpPort := "587"

	subjectLogin := "Subject: ECOTRACK | Login Approval Code\r\n"
	subjectSignup := "Subject: ECOTRACK | Email Verification\r\n"
	mime := "MIME-version: 1.0;\r\nContent-Type: text/html; charset=\"UTF-8\";\r\n\r\n"

	bodyTemplate := `
	<html>
	<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; text-align: center;">
		<div style="max-width: 500px; background-color: #ffffff; padding: 20px; margin: 0 auto; border-radius: 8px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); text-align: center;">
		<div style="background-color: #63AF2F; padding: 20px; border-top-left-radius: 8px; border-top-right-radius: 8px;">
			<img src="https://api.interphaselabs.com/static/logo.png" alt="EcoTrack Logo" style="max-width: 300px; margin-bottom: 10px;" />
		</div>
		<h2 style="color: #333;">Verification Code</h2>
		<p style="font-size: 16px; color: #555;">Hi!</p>
		<p style="font-size: 16px; color: #555;">%s</p>
		<div style="font-size: 32px; font-weight: bold; color: #000; letter-spacing: 5px; padding: 10px; border: 2px solid #ddd; display: inline-block; margin: 20px 0;">
			%s
		</div>
		<p style="font-size: 14px; color: #555;">Please complete the account verification process in <b>15 minutes</b>.</p>
		<p style="font-size: 14px; color: #63AF2F; font-weight: bold;">EcoTrack</p>
		<p style="font-size: 12px; color: #888; margin-top: 20px;">This is an automated email. Please do not reply to this email.</p>
		</div>
	</body>
	</html>`

	var message []byte
	if user.Verified {
		body := fmt.Sprintf(bodyTemplate, "Here is your login verification code", token)
		message = []byte(subjectLogin + mime + body)
	} else {
		body := fmt.Sprintf(bodyTemplate, "Here is your email verification code", token)
		message = []byte(subjectSignup + mime + body)
	}

	auth := smtp.PlainAuth("", from, password, smtpHost)
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, message)
	if err != nil {
		return err
	}

	fmt.Println("Verification Email Sent!")
	return nil
}
