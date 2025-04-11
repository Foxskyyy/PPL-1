package utils

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
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

func GetUserByEmail(email string) (*models.User, error) {
	var user models.User
	if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}
