package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID           uint              `gorm:"primaryKey" json:"id"`
	Email        string            `gorm:"unique" json:"email"`
	Password     string            `json:"-"`
	DisplayName  string            `json:"displayname"`
	RefreshToken string            `json:"refresh_token,omitempty"`
	Verified     bool              `gorm:"default:false" json:"verified"`
	VerifyToken  string            `gorm:"default:null" json:"verify_token"`
	Provider     string            `json:"provider"`
	ProviderID   string            `json:"provider_id"`
	CreatedAt    time.Time         `json:"created_at"`
	Memberships  []UserGroupMember `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"` // Fixed
}

type UserGroup struct {
	ID        uint              `gorm:"primaryKey" json:"id"`
	Name      string            `gorm:"unique" json:"name"`
	CreatedAt time.Time         `json:"created_at"`
	Devices   []Device          `gorm:"foreignKey:UserGroupID;constraint:OnDelete:CASCADE"`
	Location  JSONArray         `gorm:"type:jsonb" json:"location"`
	Members   []UserGroupMember `gorm:"foreignKey:UserGroupID;constraint:OnDelete:CASCADE"` // Fixed
}

type UserGroupMember struct {
	UserID      uint      `gorm:"primaryKey" json:"user_id"`
	UserGroupID uint      `gorm:"primaryKey" json:"user_group_id"`
	IsAdmin     bool      `gorm:"default:false" json:"is_admin"`
	CreatedAt   time.Time `json:"created_at"`
	User        User      `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;references:ID"`
	UserGroup   UserGroup `gorm:"foreignKey:UserGroupID;constraint:OnDelete:CASCADE;references:ID"`
}

func (ugm *UserGroupMember) BeforeCreate(tx *gorm.DB) error {
	var count int64
	tx.Model(&UserGroupMember{}).Where("user_group_id = ?", ugm.UserGroupID).Count(&count)
	if count >= 4 {
		return fmt.Errorf("a user group cannot have more than 4 users")
	}
	return nil
}

type Device struct {
	ID          string    `gorm:"primaryKey"`
	UserGroupID uint      `gorm:"index"`
	UserGroup   UserGroup `gorm:"foreignKey:UserGroupID;constraint:OnDelete:CASCADE;"`
	Name        string
	Location    string
	CreatedAt   time.Time
	WaterUsages []WaterUsage `gorm:"foreignKey:DeviceID"`
}

type WaterUsage struct {
	ID         uint      `gorm:"primaryKey"`
	DeviceID   string    `gorm:"index" json:"device_id"`
	Device     Device    `gorm:"constraint:OnDelete:CASCADE;"`
	FlowRate   float64   `json:"flow_rate"`
	TotalUsage float64   `json:"total_usage"`
	RecordedAt time.Time `gorm:"index" json:"recorded_at"`
}

type Notification struct {
	ID        uint   `gorm:"primaryKey"`
	DeviceID  string `gorm:"index"`
	Device    Device `gorm:"foreignKey:DeviceID;references:ID"`
	Message   string
	Threshold float64
	CreatedAt time.Time
}

type DailyUsage struct {
	ID         uint      `gorm:"primaryKey"`
	DeviceID   string    `gorm:"index"`
	Date       time.Time `gorm:"type:date"`
	TotalUsage float64
	Notified   bool `gorm:"default:false"`
}

type JSONArray []string

func (j *JSONArray) Scan(value interface{}) error {
	if value == nil {
		*j = JSONArray{}
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("invalid type assertion")
	}
	return json.Unmarshal(bytes, j)
}

func (j JSONArray) Value() (driver.Value, error) {
	if j == nil {
		return "[]", nil
	}
	return json.Marshal(j)
}
