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
	var members []models.UserGroupMember
	config.DB.Where("user_group_id = ?", groupID).Find(&members)
	userIDs := make([]uint, 0, len(members))
	for _, m := range members {
		userIDs = append(userIDs, m.UserID)
	}
	var users []models.User
	if len(userIDs) > 0 {
		config.DB.Where("id IN ?", userIDs).Find(&users)
	}
	result := make([]*model.User, 0, len(users))
	for _, u := range users {
		displayName := &u.DisplayName
		result = append(result, &model.User{
			ID:          strconv.Itoa(int(u.ID)),
			Username:    u.Username,
			Email:       u.Email,
			DisplayName: displayName,
			Verified:    u.Verified,
			CreatedAt:   u.CreatedAt,
		})
	}
	return result
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
