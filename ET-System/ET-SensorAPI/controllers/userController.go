package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func CreateUser(c *gin.Context) {
	var user models.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := config.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusCreated, user)
}

func GetUsers(c *gin.Context) {
	var users []models.User
	config.DB.Find(&users)
	c.JSON(http.StatusOK, users)
}

func AssignUserToGroup(c *gin.Context) {
	var userGroupMember models.UserGroupMember
	if err := c.ShouldBindJSON(&userGroupMember); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := config.DB.First(&user, userGroupMember.UserID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	var group models.UserGroup
	if err := config.DB.First(&group, userGroupMember.UserGroupID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User group not found"})
		return
	}

	var count int64
	config.DB.Model(&models.UserGroupMember{}).Where("user_group_id = ?", userGroupMember.UserGroupID).Count(&count)
	if count >= 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User group cannot have more than 4 users"})
		return
	}

	if err := config.DB.Create(&userGroupMember).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to assign user to group"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User assigned to group successfully", "user_group_member": userGroupMember})
}

func GetUserData(c *gin.Context) {
	var request struct {
		Email string `json:"email" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: Email is required"})
		return
	}

	var user models.User
	if err := config.DB.Where("email = ?", request.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":          user.ID,
		"email":       user.Email,
		"displayname": user.DisplayName, // Assuming the User model has a Name field
	})
}
