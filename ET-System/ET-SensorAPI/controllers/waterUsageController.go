package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"
	"regexp"

	"github.com/gin-gonic/gin"
)

var etUUIDRegex = regexp.MustCompile(`^ET-[a-f0-9\-]{36}$`)

func CreateWaterUsage(c *gin.Context) {
	var waterUsage models.WaterUsage

	if err := c.ShouldBindJSON(&waterUsage); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if !etUUIDRegex.MatchString(waterUsage.DeviceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Device ID format. Expected ET-UUID"})
		return
	}

	var device models.Device
	if err := config.DB.Where("id = ?", waterUsage.DeviceID).First(&device).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device not found"})
		return
	}

	if err := config.DB.Create(&waterUsage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record water usage"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":     "Water usage recorded successfully",
		"water_usage": waterUsage,
	})
}

func GetWaterUsage(c *gin.Context) {
	var waterUsages []models.WaterUsage
	if err := config.DB.Preload("Device").Find(&waterUsages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch water usage records"})
		return
	}
	c.JSON(http.StatusOK, waterUsages)
}
