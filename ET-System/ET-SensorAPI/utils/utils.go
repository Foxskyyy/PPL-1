package utils

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"time"
)

func GetUserUsageData(userID uint) ([]models.WaterUsage, error) {
	startTime := time.Now().AddDate(0, -3, 0)

	var waterUsage []models.WaterUsage
	err := config.DB.Where("device_id IN (?) AND recorded_at >= ?",
		config.DB.Table("devices").Select("id").Where("user_id = ?", userID),
		startTime,
	).Find(&waterUsage).Error
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
