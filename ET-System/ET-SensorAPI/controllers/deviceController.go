package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func CreateDevice(c *gin.Context) {
	var request map[string]interface{}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"})
		return
	}

	var userGroupID uint
	switch v := request["user_group_id"].(type) {
	case float64:
		userGroupID = uint(v)
	case string:
		parsedID, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_group_id format"})
			return
		}
		userGroupID = uint(parsedID)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_group_id format"})
		return
	}

	id, _ := request["id"].(string)
	name, _ := request["name"].(string)
	location, _ := request["location"].(string)

	device := models.Device{
		ID:          id,
		UserGroupID: userGroupID,
		Name:        name,
		Location:    location,
	}

	if err := config.DB.Create(&device).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create device"})
		return
	}

	c.JSON(http.StatusCreated, device)
}

func GetDevices(c *gin.Context) {
	var devices []models.Device
	config.DB.Find(&devices)
	c.JSON(http.StatusOK, devices)
}

func GetDevicesByGroup(c *gin.Context) {
	groupID := c.Param("group_id")

	var devices []models.Device
	if err := config.DB.
		Preload("WaterUsages").
		Where("user_group_id = ?", groupID).
		Find(&devices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch devices"})
		return
	}

	for i := range devices {
		var totalUsage float64
		config.DB.Table("water_usages").
			Where("device_id = ?", devices[i].ID).
			Select("SUM(total_usage)").
			Scan(&totalUsage)
		devices[i].WaterUsages = []models.WaterUsage{{TotalUsage: totalUsage}}
	}

	c.JSON(http.StatusOK, devices)
}

type WaterUsageLog struct {
	DeviceName string    `json:"device_name"`
	FlowRate   float64   `json:"flow_rate"`
	RecordedAt time.Time `json:"recorded_at"`
}

func GetDeviceLogs(c *gin.Context) {
	groupID := c.Param("group_id")

	var logs []WaterUsageLog
	if err := config.DB.Table("water_usages").
		Joins("JOIN devices ON devices.id = water_usages.device_id").
		Where("devices.user_group_id = ?", groupID).
		Order("water_usages.recorded_at DESC").
		Select("devices.name AS device_name, water_usages.flow_rate, water_usages.recorded_at").
		Scan(&logs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch usage logs"})
		return
	}

	c.JSON(http.StatusOK, logs)
}
