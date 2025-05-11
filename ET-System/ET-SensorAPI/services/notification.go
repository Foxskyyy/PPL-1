// services/notification_service.go
package services

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"fmt"
	"time"
)

func CheckUsageNotifications() {
	today := time.Now().UTC().Truncate(24 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)

	var devices []models.Device
	config.DB.Preload("WaterUsages").Find(&devices)

	for _, device := range devices {
		var todayUsage float64
		for _, usage := range device.WaterUsages {
			if usage.RecordedAt.After(today) {
				todayUsage += usage.TotalUsage
			}
		}

		var dailyUsage models.DailyUsage
		config.DB.Where("device_id = ? AND date = ?", device.ID, yesterday).First(&dailyUsage)

		if dailyUsage.TotalUsage > 0 {
			increase := ((todayUsage - dailyUsage.TotalUsage) / dailyUsage.TotalUsage) * 100
			if increase > 0 {

				message := fmt.Sprintf("Water usage increased by %.2f%% compared to yesterday", increase)
				notification := models.Notification{
					DeviceID:  device.ID,
					Message:   message,
					Threshold: increase,
					CreatedAt: time.Now(),
				}
				config.DB.Create(&notification)
			}
		}

		config.DB.Save(&models.DailyUsage{
			DeviceID:   device.ID,
			Date:       today,
			TotalUsage: todayUsage,
		})
	}
}
