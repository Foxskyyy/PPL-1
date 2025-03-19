package main

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"fmt"
)

func migrate() {
	config.ConnectDB()

	err := config.DB.AutoMigrate(
		&models.User{},
		&models.UserGroup{},
		&models.UserGroupMember{},
		&models.Device{},
		&models.WaterUsage{},
		&models.ElectricityUsage{},
	)
	if err != nil {
		fmt.Println("❌ Migration failed:", err)
	} else {
		fmt.Println("✅ Migration completed successfully!")
	}
}
