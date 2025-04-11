package utils

import (
	config "ET-SensorAPI/config"
	"ET-SensorAPI/graph/model"
	models "ET-SensorAPI/models"
	"errors"
	"strconv"

	"gorm.io/gorm"
)

func String(v string) *string {
	return &v
}

func Int32(v int) int32 {
	return int32(v)
}

func FetchUserGroupIDs(userID uint) []int {
	var memberships []models.UserGroupMember
	config.DB.Where("user_id = ?", userID).Find(&memberships)
	var ids []int
	for _, m := range memberships {
		ids = append(ids, int(m.UserGroupID))
	}
	return ids
}

func FetchGroupUsers(groupID uint) []*model.User {
	var memberships []models.UserGroupMember
	config.DB.Where("user_group_id = ?", groupID).Find(&memberships)

	var users []*model.User
	for _, m := range memberships {
		var user models.User
		if err := config.DB.First(&user, m.UserID).Error; err == nil {
			groupInts := FetchUserGroupIDs(user.ID)
			var userGroups []*model.UserGroup
			for _, id := range groupInts {
				userGroups = append(userGroups, &model.UserGroup{ID: strconv.Itoa(id)})
			}
			users = append(users, &model.User{
				ID:       strconv.Itoa(int(user.ID)),
				Username: user.Username,
				Email:    user.Email,
				Groups:   userGroups,
			})
		}
	}
	return users
}

func FetchDeviceByID(deviceID string) (*models.Device, error) {
	var device models.Device
	if err := config.DB.First(&device, deviceID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("device not found")
		}
		return nil, err
	}
	return &device, nil
}
