package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"
	"strconv"

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
