package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"bytes"
	"io"
	"net/http"
	"regexp"

	"github.com/gin-gonic/gin"
)

var etUUIDRegex = regexp.MustCompile(`^ET-[a-f0-9A-F\-]+$`)

func CreateWaterUsage(c *gin.Context) {
	var waterUsage models.WaterUsage

	body, _ := io.ReadAll(c.Request.Body)

	c.Request.Body = io.NopCloser(bytes.NewBuffer(body))

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

func GetDeviceWaterUsage(c *gin.Context) {
	deviceID := c.Param("device_id")

	var totalUsage float64
	if err := config.DB.Table("water_usages").Where("device_id = ?", deviceID).Select("SUM(usage)").Scan(&totalUsage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch usage"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"device_id": deviceID, "total_usage": totalUsage})
}
