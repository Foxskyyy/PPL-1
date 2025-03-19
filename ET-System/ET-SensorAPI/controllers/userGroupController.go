package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func CreateUserGroup(c *gin.Context) {
	var group models.UserGroup
	if err := c.ShouldBindJSON(&group); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := config.DB.Create(&group).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user group"})
		return
	}

	c.JSON(http.StatusCreated, group)
}

func GetUserGroups(c *gin.Context) {
	var groups []models.UserGroup
	config.DB.Preload("Users").Find(&groups)
	c.JSON(http.StatusOK, groups)
}
