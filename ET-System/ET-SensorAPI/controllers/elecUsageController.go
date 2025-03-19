package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func CreateElectricityUsage(c *gin.Context) {
	var electricityUsage models.ElectricityUsage
	if err := c.ShouldBindJSON(&electricityUsage); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := config.DB.Create(&electricityUsage).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record electricity usage"})
		return
	}

	c.JSON(http.StatusCreated, electricityUsage)
}

func GetElectricityUsage(c *gin.Context) {
	var electricityUsages []models.ElectricityUsage
	config.DB.Find(&electricityUsages)
	c.JSON(http.StatusOK, electricityUsages)
}
