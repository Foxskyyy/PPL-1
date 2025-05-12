package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"bytes"
	"io"
	"net/http"
	"regexp"
	"time"

	"github.com/gin-gonic/gin"
)

var etUUIDRegex = regexp.MustCompile(`^ET-[a-f0-9A-F\-]+$`)

func CreateWaterUsage(c *gin.Context) {
	var waterUsage models.WaterUsage

	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}
	c.Request.Body = io.NopCloser(bytes.NewBuffer(body))

	if err := c.ShouldBindJSON(&waterUsage); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON format: " + err.Error()})
		return
	}

	if waterUsage.TotalUsage <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "total_usage must be positive"})
		return
	}

	if !etUUIDRegex.MatchString(waterUsage.DeviceID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Device ID format (expected ET-XXX)"})
		return
	}

	tx := config.DB.Begin()
	defer tx.Rollback()

	var device models.Device
	if err := tx.Where("id = ?", waterUsage.DeviceID).First(&device).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	waterUsage.RecordedAt = time.Now()
	if err := tx.Create(&waterUsage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record water usage"})
		return
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Transaction failed"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Water usage recorded",
		"data": gin.H{
			"device_id":   waterUsage.DeviceID,
			"flow_rate":   waterUsage.FlowRate,
			"total_usage": waterUsage.TotalUsage,
			"recorded_at": waterUsage.RecordedAt.Format(time.RFC3339),
		},
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
