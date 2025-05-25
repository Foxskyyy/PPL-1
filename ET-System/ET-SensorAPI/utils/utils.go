package utils

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"errors"
	"fmt"
	"net/smtp"
	"os"
	"strings"
	"time"
)

func GetUserUsageData(userID uint) ([]models.WaterUsage, error) {
	startTime := time.Now().AddDate(0, -3, 0)

	var waterUsage []models.WaterUsage

	subQuery := config.DB.
		Table("devices").
		Select("devices.id").
		Joins("JOIN user_groups ON user_groups.id = devices.user_group_id").
		Joins("JOIN user_group_members ON user_group_members.user_group_id = user_groups.id").
		Where("user_group_members.user_id = ?", userID)

	err := config.DB.
		Where("device_id IN (?) AND recorded_at >= ?", subQuery, startTime).
		Find(&waterUsage).Error

	if err != nil {
		return nil, err
	}

	return waterUsage, nil
}

func GetGroupUsageData(groupID uint) ([]models.WaterUsage, error) {
	startTime := time.Now().AddDate(0, -3, 0)

	var waterUsage []models.WaterUsage

	subQuery := config.DB.
		Table("devices").
		Select("devices.id").
		Joins("JOIN user_groups ON user_groups.id = devices.user_group_id").
		Where("user_groups.id = ?", groupID)

	err := config.DB.
		Where("device_id IN (?) AND recorded_at >= ?", subQuery, startTime).
		Find(&waterUsage).Error

	if err != nil {
		return nil, err
	}

	return waterUsage, nil
}

func GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func SendInvitationEmail(senderEmail string, receiverEmail string, groupName string) error {
	var user models.User
	sender := config.DB.Where("email = ?", senderEmail).First(&user)
	if sender.Error != nil {
		return sender.Error
	}

	from := os.Getenv("SMTP_EMAIL")
	password := os.Getenv("SMTP_PASSWORD")
	if from == "" || password == "" {
		return errors.New("SMTP credentials are not set")
	}

	to := []string{receiverEmail}
	smtpHost := "smtp.gmail.com"
	smtpPort := "587"

	subject := "Subject: ECOTRACK | You Have Been Invited To Join Group\r\n"
	mime := "MIME-version: 1.0;\r\nContent-Type: text/html; charset=\"UTF-8\";\r\n\r\n"

	bodyTemplate := `
	<html>
	<body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; text-align: center;">
		<div style="max-width: 500px; background-color: #ffffff; padding: 20px; margin: 0 auto; border-radius: 8px; box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); text-align: center;">
		<div style="background-color: #63AF2F; padding: 20px; border-top-left-radius: 8px; border-top-right-radius: 8px;">
			<img src="https://api2.interphaselabs.com/media/images/logo.png" alt="EcoTrack Logo" style="max-width: 300px; margin-bottom: 10px;" />
		</div>
		<h2 style="color: #333;">Group Invitation</h2>
		<p style="font-size: 16px; color: #555;">Hi!</p>
		<p style="font-size: 16px; color: #555;">You've been invited to join <b>%s</b> group on EcoTrack.</p>
		
		<div style="margin: 30px auto; width: 85%%; border-radius: 12px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.08);">
			<div style="background-color: #63AF2F; color: white; padding: 12px 15px; text-align: left; font-size: 16px; font-weight: bold; letter-spacing: 0.5px; border-bottom: 3px solid rgba(0,0,0,0.1);">
				Group Details
			</div>
			<div style="background-color: #f9f9f9; padding: 0; border: 1px solid #eaeaea; border-top: none;">
				<div style="padding: 15px; border-bottom: 1px solid #eaeaea; display: flex; text-align: left;">
					<div style="width: 35%%; font-size: 15px; color: #666; font-weight: 600; padding-right: 10px;">Group:</div>
					<div style="width: 65%%; font-size: 16px; color: #333; font-weight: 500;">%s</div>
				</div>
				<div style="padding: 15px; text-align: left; display: flex;">
					<div style="width: 35%%; font-size: 15px; color: #666; font-weight: 600; padding-right: 10px;">Invited by:</div>
					<div style="width: 65%%; font-size: 16px; color: #333; font-weight: 500;">%s</div>
				</div>
			</div>
		</div>
		
		<p style="font-size: 14px; color: #555;">Please log in to your EcoTrack account to view group.</p>
		<p style="font-size: 14px; color: #63AF2F; font-weight: bold;">EcoTrack</p>
		<p style="font-size: 12px; color: #888; margin-top: 20px;">This is an automated email. Please do not reply to this email.</p>
		</div>
	</body>
</html>`

	body := fmt.Sprintf(bodyTemplate, groupName, groupName, senderEmail)
	message := []byte(subject + mime + body)

	auth := smtp.PlainAuth("", from, password, smtpHost)
	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, message)
	if err != nil {
		return err
	}

	fmt.Println("Invitation Email Sent!")
	return nil
}

func ValidateDeviceID(code string) bool {
	if !strings.HasPrefix(code, "ET-") {

		return false
	}
	return true
}
