package controllers

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func CreateUserGroup(c *gin.Context) {
	var request map[string]interface{}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"})
		return
	}

	name, ok := request["name"].(string)
	if !ok || name == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid name format"})
		return
	}
	var userID uint
	switch v := request["user_id"].(type) {
	case float64:
		userID = uint(v)
	case string:
		parsedID, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id format"})
			return
		}
		userID = uint(parsedID)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id format"})
		return
	}

	group := models.UserGroup{Name: name}
	if err := config.DB.Create(&group).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user group"})
		return
	}

	member := models.UserGroupMember{UserID: userID, UserGroupID: group.ID}
	if err := config.DB.Create(&member).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add user to group"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "User group created successfully",
		"group":   group,
		"member":  member,
	})
}

func GetDeviceGroups(c *gin.Context) {
	var groups []models.UserGroup
	if err := config.DB.Preload("Devices").Find(&groups).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve user groups"})
		return
	}
	c.JSON(http.StatusOK, groups)
}

func AddUserToGroup(c *gin.Context) {
	var userGroupMember models.UserGroupMember

	if err := c.ShouldBindJSON(&userGroupMember); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request data"})
		return
	}

	var count int64
	config.DB.Model(&models.UserGroupMember{}).
		Where("user_group_id = ?", userGroupMember.UserGroupID).
		Count(&count)

	if count >= 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User group cannot have more than 4 users"})
		return
	}

	if err := config.DB.Create(&userGroupMember).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add user to group"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "User added to group successfully", "userGroupMember": userGroupMember})
}

func GetUserGroupMembers(c *gin.Context) {
	var members []models.UserGroupMember

	if err := config.DB.Preload("User").Find(&members).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve user group members"})
		return
	}

	c.JSON(http.StatusOK, members)
}
