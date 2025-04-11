package utils

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"net/smtp"
	"os"
	"time"

	"golang.org/x/crypto/bcrypt"

	"ET-SensorAPI/config"
	"ET-SensorAPI/models"

	"github.com/golang-jwt/jwt/v4"
)

var secretKey = []byte(os.Getenv("JWT_SECRET"))

type Claims struct {
	UserID uint `json:"user_id"`
	jwt.RegisteredClaims
}

const otpChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

func GenerateToken(userID uint) (string, string, error) {
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

func AuthenticateUser(email, password string) (*models.User, error) {
	var user models.User
	result := config.DB.Where("email = ?", email).First(&user)
	if result.Error != nil {
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
	to := []string{email}
	smtpHost := "smtp.gmail.com"
	smtpPort := "587"

	subjectLogin := "Subject: ECOTRACK | Login Approval Code\r\n"
	subjectSignup := "Subject: ECOTRACK | Email Verification\r\n"
	mime := "MIME-version: 1.0;\r\nContent-Type: text/html; charset=\"UTF-8\";\r\n\r\n"

	bodyLogin := fmt.Sprintf(`
		<html>
			<body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 40px;">
				<div style="max-width: 500px; margin: auto; background: #eee; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
					<div style="text-align: center;">
						<img src="https://api.interphaselabs.com/static/logo.png" width="200" style="margin-bottom: 20px;" />
						<h2 style="color: #333;">Login Code</h2>
						<p style="font-size: 16px; color: #666;">Here is your login approval code:</p>
						<div style="font-size: 24px; font-weight: bold; color: #000; background: #ffffff; padding: 20px 30px; border-radius: 8px; display: inline-block; margin: 20px 0; line-height: 32px;">
							%s
						</div>
						<p style="font-size: 14px; color: #999;">
							If this request did not come from you, change your account password immediately to prevent further unauthorized access.
						</p>
					</div>
				</div>
			</body>
		</html>
	`, token)

	bodySignup := fmt.Sprintf(`
		<html>
			<body style="font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 40px;">
				<div style="max-width: 500px; margin: auto; background: #eee; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1);">
					<div style="text-align: center;">
						<img src="https://api.interphaselabs.com/static/logo.png" width="200" style="margin-bottom: 20px;" />
						<h2 style="color: #333;">Email Verification Code</h2>
						<p style="font-size: 16px; color: #666;">Here is your email verification code:</p>
						<div style="font-size: 24px; font-weight: bold; color: #000; background: #ffffff; padding: 20px 100px; border-radius: 8px; display: inline-block; margin: 20px 0; line-height: 32px;">
							%s
						</div>
						<p style="font-size: 14px; color: #999;">
							If this request did not come from you, change your account password immediately to prevent further unauthorized access.
						</p>
					</div>
				</div>
			</body>
		</html>
	`, token)

	var message []byte
	if user.Verified {
		message = []byte(subjectLogin + mime + bodyLogin)
	} else {
		message = []byte(subjectSignup + mime + bodySignup)
	}

	auth := smtp.PlainAuth("", from, password, smtpHost)
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, message)
	if err != nil {
		return err
	}

	fmt.Println("Verification Email Sent!")
	return nil
}
