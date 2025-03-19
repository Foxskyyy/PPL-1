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
	from := os.Getenv("SMTP_EMAIL")
	password := os.Getenv("SMTP_PASSWORD")
	to := []string{email}
	smtpHost := "smtp.gmail.com"
	smtpPort := "587"

	message := []byte(fmt.Sprintf("Subject: ECOTRACK | Email Verification\n\nHere is your Email Verification Code : %s", token))

	auth := smtp.PlainAuth("", from, password, smtpHost)

	fmt.Print("Verification Email Sent!")

	return smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, message)
}
