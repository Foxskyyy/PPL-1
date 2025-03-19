package utils

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"time"
)

func GetUserUsageData(userID uint) ([]models.WaterUsage, []models.ElectricityUsage, error) {
	startTime := time.Now().AddDate(0, -3, 0)

	var waterUsage []models.WaterUsage
	err := config.DB.Where("device_id IN (?) AND recorded_at >= ?",
		config.DB.Table("devices").Select("id").Where("user_id = ?", userID),
		startTime,
	).Find(&waterUsage).Error
	if err != nil {
		return nil, nil, err
	}

	var electricityUsage []models.ElectricityUsage
	err = config.DB.Where("user_id = ? AND recorded_at >= ?", userID, startTime).Find(&electricityUsage).Error
	if err != nil {
		return nil, nil, err
	}

	return waterUsage, electricityUsage, nil
}
