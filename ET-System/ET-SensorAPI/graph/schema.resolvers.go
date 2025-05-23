package graph

// THIS CODE WILL BE UPDATED WITH SCHEMA CHANGES. PREVIOUS IMPLEMENTATION FOR SCHEMA CHANGES WILL BE KEPT IN THE COMMENT SECTION. IMPLEMENTATION FOR UNCHANGED SCHEMA WILL BE KEPT.

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/graph/model"
	"ET-SensorAPI/models"
	"ET-SensorAPI/services"
	"ET-SensorAPI/utils"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"cloud.google.com/go/auth/credentials/idtoken"
	"gorm.io/gorm"
)

type Resolver struct {
	DB *gorm.DB
}

// Login is the resolver for the login field.
func (r *mutationResolver) Login(ctx context.Context, email string, password string) (*model.AuthPayload, error) {
	user, err := utils.AuthenticateUser(email, password)
	if err != nil {
		return nil, err
	}

	code, _ := utils.GenerateOTP()
	token, _, err := utils.GenerateToken(user.ID)
	if err != nil {
		return nil, errors.New("failed to generate verification token")
	}

	if err := utils.SendVerificationEmail(email, code); err != nil {
		return nil, errors.New("failed to send verification email")
	}

	user.VerifyToken = code
	user.RefreshToken = token

	if err := config.DB.Save(&user).Error; err != nil {
		return nil, errors.New("failed to save user")
	}

	var memberships []models.UserGroupMember
	if err := config.DB.
		Preload("User").
		Preload("UserGroup").
		Where("user_id = ?", user.ID).
		Find(&memberships).Error; err != nil {
		return nil, errors.New("failed to load memberships")
	}

	authUser := utils.ConvertAuthedUserToGQL(*user, memberships)
	return &model.AuthPayload{
		User:  authUser,
		Token: token,
	}, nil
}

// Register is the resolver for the register field.
func (r *mutationResolver) Register(ctx context.Context, displayName string, email string, password string) (*string, error) {
	var exists models.User
	if err := config.DB.Where("email = ?", email).First(&exists).Error; err == nil {
		return nil, errors.New("email already registered")
	}

	hashed, err := utils.HashPassword(password)
	if err != nil {
		return nil, errors.New("failed to hash password")
	}

	token, _ := utils.GenerateOTP()
	newUser := models.User{
		Email:       email,
		DisplayName: displayName,
		Password:    hashed,
		Verified:    false,
		VerifyToken: token,
	}

	if err := config.DB.Create(&newUser).Error; err != nil {
		return nil, errors.New("failed to create user")
	}

	if err := utils.SendVerificationEmail(email, token); err != nil {
		return nil, errors.New("failed to send verification email")
	}

	successMessage := "Registration successful. Please check your email for verification."
	return &successMessage, nil
}

// AssignUserToGroup is the resolver for the assignUserToGroup field.
func (r *mutationResolver) AssignUserToGroup(ctx context.Context, senderEmail string, userGroupID int32, receiverEmail string) (*string, error) {

	tx := config.DB.Begin()
	if tx.Error != nil {
		return nil, fmt.Errorf("failed to start transaction: %w", tx.Error)
	}

	var user models.User
	if err := tx.Where("email = ?", receiverEmail).First(&user).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("user not found: %w", err)
	}

	var group models.UserGroup
	if err := tx.First(&group, userGroupID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("group not found: %w", err)
	}

	var count int64
	if err := tx.Model(&models.UserGroupMember{}).
		Where("user_group_id = ?", group.ID).
		Count(&count).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to check member count: %w", err)
	}
	if count >= 4 {
		tx.Rollback()
		return nil, errors.New("user group cannot have more than 4 users")
	}

	membership := models.UserGroupMember{
		UserID:      user.ID,
		UserGroupID: group.ID,
		IsAdmin:     false,
	}
	if err := tx.Create(&membership).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to assign user to group: %w", err)
	}

	if err := utils.SendInvitationEmail(senderEmail, receiverEmail, group.Name); err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to send invitation email: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	successMessage := "User assigned to group successfully"
	return &successMessage, nil
}

// VerifyEmail is the resolver for the verifyEmail field.
func (r *mutationResolver) VerifyEmail(ctx context.Context, email string, token string) (*string, error) {
	var user models.User
	if err := config.DB.Where("email = ? AND verify_token = ?", email, token).First(&user).Error; err != nil {
		return nil, errors.New("invalid or expired token")
	}

	if !user.Verified {
		user.Verified = true
	}
	user.VerifyToken = ""

	if err := config.DB.Save(&user).Error; err != nil {
		return nil, errors.New("failed to verify email")
	}

	successMessage := "Email verified successfully."
	return &successMessage, nil
}

// ResendVerificationEmail is the resolver for the ResendVerificationEmail field.
func (r *mutationResolver) ResendVerificationEmail(ctx context.Context, email string) (*string, error) {
	user, err := utils.GetUserByEmail(email)
	if err != nil {
		return nil, errors.New("user not found")
	}

	accessToken, _ := utils.GenerateOTP()

	if err := utils.SendVerificationEmail(user.Email, accessToken); err != nil {
		return nil, errors.New("failed to send verification email")
	}

	successMessage := "Verification email sent successfully"
	return &successMessage, nil
}

// RequestForgotPassword is the resolver for the RequestForgotPassword field.
func (r *mutationResolver) RequestForgotPassword(ctx context.Context, email string) (*string, error) {
	user, err := utils.GetUserByEmail(email)
	if err != nil {
		return nil, errors.New("user not found")
	}

	if !user.Verified {
		return nil, errors.New("email not verified")
	}

	accessToken, _ := utils.GenerateOTP()

	if err := utils.SendVerificationEmail(user.Email, accessToken); err != nil {
		return nil, errors.New("failed to send verification email")
	}

	successMessage := "Verification email sent successfully"
	return &successMessage, nil
}

// ForgotPasswordHandler is the resolver for the ForgotPasswordHandler field.
func (r *mutationResolver) ForgotPasswordHandler(ctx context.Context, email string, password string) (*string, error) {
	user, err := utils.GetUserByEmail(email)
	if err != nil {
		return nil, errors.New("user not found")
	}

	hashed, err := utils.HashPassword(password)
	if err != nil {
		return nil, errors.New("failed to hash password")
	}

	user.Password = hashed

	if err := config.DB.Save(&user).Error; err != nil {
		return nil, errors.New("failed to update password")
	}

	successMessage := "Password reset successfully"
	return &successMessage, nil
}

// ChangeEmail is the resolver for the changeEmail field.
func (r *mutationResolver) ChangeEmail(ctx context.Context, email string, password string, newemail string) (*string, error) {
	if email == "" || password == "" || newemail == "" {
		return nil, errors.New("email, password, and new email are required")
	}
	if email == newemail {
		return nil, errors.New("new email must be different from current email")
	}

	user, err := utils.GetUserByEmail(email)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	_, err = utils.AuthenticateUser(email, password)
	if err != nil {
		return nil, fmt.Errorf("authentication failed: %w", err)
	}

	var existingUser models.User
	if err := config.DB.Where("email = ?", newemail).First(&existingUser).Error; err == nil {
		return nil, errors.New("new email is already registered")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("error checking email availability: %w", err)
	}

	verifyToken, err := utils.GenerateOTP()
	if err != nil {
		return nil, fmt.Errorf("failed to generate verification token: %w", err)
	}

	user.Email = newemail
	user.Verified = false
	user.VerifyToken = verifyToken

	if err := config.DB.Save(&user).Error; err != nil {
		return nil, fmt.Errorf("failed to update email: %w", err)
	}

	if err := utils.SendVerificationEmail(newemail, verifyToken); err != nil {
		return nil, fmt.Errorf("failed to send verification email: %w", err)
	}

	successMessage := "Email changed successfully. Please check your new email for verification."
	return &successMessage, nil
}

// CreateUserGroup is the resolver for the createUserGroup field.
func (r *mutationResolver) CreateUserGroup(ctx context.Context, userID int32, groupName string) (*model.UserGroup, error) {
	tx := config.DB.Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	group := models.UserGroup{Name: groupName}
	if err := tx.Create(&group).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to create group: %w", err)
	}

	member := models.UserGroupMember{
		UserID:      uint(userID),
		UserGroupID: group.ID,
		IsAdmin:     true,
	}
	if err := tx.Create(&member).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to add creator to group: %w", err)
	}

	var members []models.UserGroupMember
	if err := tx.Preload("User").Preload("UserGroup").
		Where("user_group_id = ?", group.ID).
		Find(&members).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to load group members: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	users := make([]*model.UserGroupMember, len(members))
	for i, m := range members {
		users[i] = &model.UserGroupMember{
			User: &model.User{
				ID:          fmt.Sprintf("%d", m.User.ID),
				Email:       m.User.Email,
				DisplayName: &m.User.DisplayName,
				Verified:    m.User.Verified,
				CreatedAt:   m.User.CreatedAt,
				Memberships: []*model.UserGroupMember{},
			},
			Group: &model.UserGroup{
				ID:        fmt.Sprintf("%d", m.UserGroup.ID),
				Name:      m.UserGroup.Name,
				CreatedAt: m.UserGroup.CreatedAt,
				Location:  m.UserGroup.Location,
			},
			IsAdmin:   m.IsAdmin,
			CreatedAt: m.CreatedAt,
		}
	}

	return &model.UserGroup{
		ID:        fmt.Sprintf("%d", group.ID),
		Name:      group.Name,
		CreatedAt: group.CreatedAt,
		Location:  group.Location,
		Users:     users,
		Devices:   []*model.Device{},
	}, nil
}

// AddDeviceToUserGroup is the resolver for the addDeviceToUserGroup field.
func (r *mutationResolver) AddDeviceToUserGroup(ctx context.Context, deviceID string, deviceName string, userGroupID int32, location string) (*model.UserGroup, error) {
	if deviceID == "" || deviceName == "" || userGroupID <= 0 {
		return nil, errors.New("deviceID, deviceName, and userGroupID are required")
	}

	if utils.ValidateDeviceID(deviceID) == false {
		return nil, errors.New("Device ID Tidak Valid")
	}

	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil || tx.Error != nil {
			tx.Rollback()
		}
	}()

	var group models.UserGroup
	if err := tx.Preload("Devices").First(&group, uint(userGroupID)).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("user group not found: %w", err)
	}

	var existingDevice models.Device
	if err := tx.Where("id = ? AND user_group_id = ?", deviceID, uint(userGroupID)).First(&existingDevice).Error; err == nil {
		tx.Rollback()
		return nil, errors.New("device with this ID already exists in the group")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		tx.Rollback()
		return nil, fmt.Errorf("error checking existing device: %w", err)
	}

	device := models.Device{
		ID:          deviceID,
		Name:        deviceName,
		Location:    location,
		UserGroupID: uint(userGroupID),
	}
	if err := tx.Create(&device).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to add device to group: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	if err := config.DB.Preload("Devices").First(&group, uint(userGroupID)).Error; err != nil {
		return nil, fmt.Errorf("failed to reload user group: %w", err)
	}

	var members []models.UserGroupMember
	if err := config.DB.Preload("User").Where("user_group_id = ?", group.ID).Find(&members).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch group members: %w", err)
	}

	devices := make([]*model.Device, 0, len(group.Devices))
	for _, d := range group.Devices {
		devices = append(devices, &model.Device{
			ID:        d.ID,
			Name:      d.Name,
			Location:  d.Location,
			CreatedAt: d.CreatedAt,
			UserGroup: &model.UserGroup{
				ID:        strconv.Itoa(int(group.ID)),
				Name:      group.Name,
				CreatedAt: group.CreatedAt,
			},
			WaterUsages: []*model.WaterUsage{},
		})
	}

	graphqlMembers := make([]*model.UserGroupMember, 0, len(members))
	for _, m := range members {
		displayName := &m.User.DisplayName
		graphqlMembers = append(graphqlMembers, &model.UserGroupMember{
			IsAdmin:   m.IsAdmin,
			CreatedAt: m.CreatedAt,
			User: &model.User{
				ID:          strconv.Itoa(int(m.User.ID)),
				Email:       m.User.Email,
				DisplayName: displayName,
				Verified:    m.User.Verified,
				CreatedAt:   m.User.CreatedAt,
				Memberships: []*model.UserGroupMember{},
			},
		})
	}

	return &model.UserGroup{
		ID:        strconv.Itoa(int(group.ID)),
		Name:      group.Name,
		CreatedAt: group.CreatedAt,
		Devices:   devices,
		Users:     graphqlMembers,
		Location:  group.Location,
	}, nil
}

// OauthLogin is the resolver for the oauthLogin field.
func (r *mutationResolver) OauthLogin(ctx context.Context, provider model.OAuthProvider, token string) (*model.AuthPayload, error) {
	if token == "" {
		return nil, errors.New("token is required")
	}

	var (
		user        models.User
		email       string
		displayName string
		providerID  string
	)

	providerStr := strings.ToLower(string(provider))

	switch provider {
	case model.OAuthProviderGoogle:
		clientID := config.GetEnv("GOOGLE_CLIENT_ID", "")
		if clientID == "" {
			return nil, errors.New("Google client ID not configured")
		}

		payload, err := idtoken.Validate(ctx, token, clientID)
		if err != nil {
			return nil, fmt.Errorf("invalid Google token: %w", err)
		}

		sub, ok1 := payload.Claims["sub"].(string)
		emailClaim, ok2 := payload.Claims["email"].(string)
		nameClaim, ok3 := payload.Claims["name"].(string)
		if !ok1 || !ok2 || !ok3 {
			return nil, errors.New("missing required claims from Google token")
		}

		providerID = sub
		email = emailClaim
		displayName = nameClaim

	case model.OAuthProviderApple:
		claims, err := utils.ValidateAppleToken(token)
		if err != nil {
			return nil, fmt.Errorf("invalid Apple token: %w", err)
		}

		sub, ok := claims["sub"].(string)
		if !ok {
			return nil, errors.New("missing 'sub' in Apple token")
		}
		providerID = sub
		if emailVal, ok := claims["email"].(string); ok {
			email = emailVal
		}

	default:
		return nil, errors.New("unsupported OAuth provider")
	}

	err := config.DB.Where("provider = ? AND provider_id = ?", providerStr, providerID).First(&user).Error

	if errors.Is(err, gorm.ErrRecordNotFound) && email != "" {
		err = config.DB.Where("email = ?", email).First(&user).Error
	}

	if errors.Is(err, gorm.ErrRecordNotFound) {
		user = models.User{
			Email:       email,
			DisplayName: displayName,
			Verified:    true,
			Provider:    providerStr,
			ProviderID:  providerID,
			CreatedAt:   time.Now(),
		}

		if err := config.DB.Create(&user).Error; err != nil {
			return nil, fmt.Errorf("failed to create user: %w", err)
		}
	} else if err != nil {
		return nil, fmt.Errorf("failed to fetch user: %w", err)
	} else {
		if user.Email != email && email != "" {
			var existingUser models.User
			if err := config.DB.Where("email = ?", email).First(&existingUser).Error; err == nil && existingUser.ID != user.ID {
				return nil, errors.New("email already registered to another user")
			}
			user.Email = email
		}

		if displayName != "" && user.DisplayName != displayName {
			user.DisplayName = displayName
		}

		user.Provider = providerStr
		user.ProviderID = providerID
		user.Verified = true

		if err := config.DB.Save(&user).Error; err != nil {
			return nil, fmt.Errorf("failed to update user: %w", err)
		}
	}

	jwtToken, refreshToken, err := utils.GenerateToken(user.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to generate JWT: %w", err)
	}

	user.RefreshToken = refreshToken
	if err := config.DB.Save(&user).Error; err != nil {
		return nil, fmt.Errorf("failed to update refresh token: %w", err)
	}

	groupIDs := utils.FetchUserGroupIDs(user.ID)
	memberships := make([]*model.UserGroupMember, 0, len(groupIDs))
	for _, id := range groupIDs {
		memberships = append(memberships, &model.UserGroupMember{
			Group: &model.UserGroup{ID: strconv.Itoa(int(id))},
		})
	}

	gqlUser := &model.User{
		ID:          strconv.Itoa(int(user.ID)),
		Email:       user.Email,
		DisplayName: &user.DisplayName,
		Verified:    user.Verified,
		CreatedAt:   user.CreatedAt,
		Memberships: memberships,
	}

	return &model.AuthPayload{
		User:  gqlUser,
		Token: jwtToken,
	}, nil
}

// Logout is the resolver for the logout field.
func (r *mutationResolver) Logout(ctx context.Context, email string) (*string, error) {
	var user models.User
	if err := config.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}

	user.RefreshToken = ""
	if err := config.DB.Save(&user).Error; err != nil {
		return nil, err
	}

	successMessage := "Logged out successfully"
	return &successMessage, nil
}

// AddLocation is the resolver for the addLocation field.
func (r *mutationResolver) AddLocation(ctx context.Context, groupId int32, locationName string) (*string, error) {
	var group models.UserGroup

	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Set("gorm:query_option", "FOR UPDATE").
		Where("id = ?", groupId).
		First(&group).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("group not found: %w", err)
	}

	updatedLocations := append(group.Location, locationName)

	if err := tx.Model(&group).
		Update("location", updatedLocations).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to update locations: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("transaction failed: %w", err)
	}

	successMessage := "Location added successfully"
	return &successMessage, nil
}

// RemoveDevice is the resolver for the removeDevice field.
func (r *mutationResolver) RemoveDevice(ctx context.Context, groupID int32, deviceID string) (*string, error) {
	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	var group models.UserGroup
	if err := tx.First(&group, groupID).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("user group not found")
	}

	var device models.Device
	if err := tx.Where("id = ? AND user_group_id = ?", deviceID, groupID).First(&device).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("device not found in specified group")
	}

	if err := tx.Where("device_id = ?", deviceID).Delete(&models.WaterUsage{}).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to delete device usage history: %w", err)
	}

	if err := tx.Delete(&device).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to delete device: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("transaction failed: %w", err)
	}

	successMessage := "Device removed successfully"
	return &successMessage, nil
}

// CheckUsageNotifications is the resolver for the checkUsageNotifications field.
func (r *mutationResolver) CheckUsageNotifications(ctx context.Context) (bool, error) {
	go services.CheckUsageNotifications()
	return true, nil
}

// EditMember is the resolver for the editMember field.
func (r *mutationResolver) EditMember(ctx context.Context, groupID int32, changedUserID int32, action string) (*string, error) {
	var group models.UserGroup

	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Set("gorm:query_option", "FOR UPDATE").
		Where("id = ?", groupID).
		First(&group).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("group not found: %w", err)
	}

	var membership models.UserGroupMember
	if err := tx.Debug().Where("user_id = ? AND user_group_id = ?", changedUserID, groupID).First(&membership).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("user not found in specified group")
	}

	switch action {
	case "REMOVE":
		if err := tx.Delete(&membership).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("failed to remove user from group: %w", err)
		}
	case "ADMIN_PERMS":
		membership.IsAdmin = true
		if err := tx.Save(&membership).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("failed to update user permission: %w", err)
		}
	case "MEMBER_PERMS":
		membership.IsAdmin = false
		if err := tx.Save(&membership).Error; err != nil {
			tx.Rollback()
			return nil, fmt.Errorf("failed to update user permission: %w", err)
		}
	default:
		tx.Rollback()
		return nil, fmt.Errorf("invalid action: %s", action)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("transaction failed: %w", err)
	}

	successMessage := "User updated successfully"
	return &successMessage, nil
}

// Users is the resolver for the users field.
func (r *queryResolver) Users(ctx context.Context) ([]*model.User, error) {
	var dbUsers []models.User
	if err := config.DB.WithContext(ctx).
		Preload("Memberships.UserGroup").
		Find(&dbUsers).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch users: %w", err)
	}

	result := make([]*model.User, len(dbUsers))
	for i, u := range dbUsers {
		memberships := make([]*model.UserGroupMember, len(u.Memberships))
		for j, m := range u.Memberships {
			memberships[j] = &model.UserGroupMember{
				Group: &model.UserGroup{
					ID:        fmt.Sprintf("%d", m.UserGroup.ID),
					Name:      m.UserGroup.Name,
					CreatedAt: m.UserGroup.CreatedAt,
					Location:  m.UserGroup.Location,
				},
				User:      &model.User{ID: fmt.Sprintf("%d", u.ID)},
				IsAdmin:   m.IsAdmin,
				CreatedAt: m.CreatedAt,
			}
		}

		var displayName *string
		if u.DisplayName != "" {
			displayName = &u.DisplayName
		}

		result[i] = &model.User{
			ID:          fmt.Sprintf("%d", u.ID),
			Email:       u.Email,
			DisplayName: displayName,
			Verified:    u.Verified,
			CreatedAt:   u.CreatedAt,
			Memberships: memberships,
		}
	}
	return result, nil
}

// UserGroups is the resolver for the userGroups field.
func (r *queryResolver) UserGroups(ctx context.Context) ([]*model.UserGroup, error) {
	var dbGroups []models.UserGroup

	// Optimized preloading with all necessary relationships
	err := config.DB.
		Preload("Members.User").
		Preload("Devices.WaterUsages"). // Load devices with their water usages
		Find(&dbGroups).Error

	if err != nil {
		return nil, fmt.Errorf("failed to fetch groups: %w", err)
	}

	result := make([]*model.UserGroup, len(dbGroups))

	for i, dbGroup := range dbGroups {
		// Convert members
		members := make([]*model.UserGroupMember, len(dbGroup.Members))
		for j, g := range dbGroup.Members {
			members[j] = &model.UserGroupMember{
				User: &model.User{
					ID:          fmt.Sprintf("%d", g.User.ID),
					Email:       g.User.Email,
					DisplayName: &g.User.DisplayName,
					Verified:    g.User.Verified,
					CreatedAt:   g.User.CreatedAt,
				},
				Group: &model.UserGroup{
					ID:        fmt.Sprintf("%d", g.UserGroup.ID),
					Name:      g.UserGroup.Name,
					CreatedAt: g.UserGroup.CreatedAt,
					Location:  g.UserGroup.Location,
				},
				IsAdmin:   g.IsAdmin,
				CreatedAt: g.CreatedAt,
			}
		}

		devices := make([]*model.Device, len(dbGroup.Devices))
		for k, h := range dbGroup.Devices {
			waterUsages := make([]*model.WaterUsage, len(h.WaterUsages))
			for l, dbUsage := range h.WaterUsages {
				waterUsages[l] = &model.WaterUsage{
					ID:         fmt.Sprintf("%d", dbUsage.ID),
					FlowRate:   dbUsage.FlowRate,
					TotalUsage: dbUsage.TotalUsage,
					RecordedAt: dbUsage.RecordedAt,
				}
			}

			devices[k] = &model.Device{
				ID:          h.ID,
				Name:        h.Name,
				Location:    h.Location,
				CreatedAt:   h.CreatedAt,
				WaterUsages: waterUsages,
			}
		}

		result[i] = &model.UserGroup{
			ID:        fmt.Sprintf("%d", dbGroup.ID),
			Name:      dbGroup.Name,
			CreatedAt: dbGroup.CreatedAt,
			Location:  dbGroup.Location,
			Users:     members,
			Devices:   devices,
		}
	}

	return result, nil
}

// Devices is the resolver for the devices field.
func (r *queryResolver) Devices(ctx context.Context) ([]*model.Device, error) {
	var devices []models.Device
	if err := config.DB.Preload("WaterUsages").Find(&devices).Error; err != nil {
		return nil, err
	}

	var result []*model.Device
	for _, d := range devices {
		var waterUsages []*model.WaterUsage
		for _, wu := range d.WaterUsages {
			waterUsages = append(waterUsages, &model.WaterUsage{
				FlowRate:   wu.FlowRate,
				TotalUsage: wu.TotalUsage,
				RecordedAt: wu.RecordedAt,
			})
		}

		var group models.UserGroup
		if err := config.DB.First(&group, d.UserGroupID).Error; err != nil {
			return nil, fmt.Errorf("failed to fetch user group for device %s: %w", d.ID, err)
		}

		result = append(result, &model.Device{
			ID:          d.ID,
			Name:        d.Name,
			Location:    d.Location,
			CreatedAt:   d.CreatedAt,
			WaterUsages: waterUsages,
			UserGroup: &model.UserGroup{
				ID:        strconv.Itoa(int(group.ID)),
				Name:      group.Name,
				CreatedAt: group.CreatedAt,
				Devices:   []*model.Device{},
				Users:     []*model.UserGroupMember{},
			},
		})
	}
	return result, nil
}

// DeviceUsage is the resolver for the deviceUsage field.
func (r *queryResolver) DeviceUsage(ctx context.Context, groupID int32) ([]*model.DeviceUsageData, error) {
	var devices []models.Device
	if err := config.DB.Preload("WaterUsages").Where("user_group_id = ?", groupID).Find(&devices).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch devices: %w", err)
	}

	deviceMap := make(map[string]*model.DeviceUsageData, len(devices))
	groupTotal := float64(0)

	for _, device := range devices {
		deviceTotal := float64(0)

		if device.WaterUsages != nil {
			for _, usage := range device.WaterUsages {
				deviceTotal += usage.TotalUsage
			}
		}

		deviceMap[device.ID] = &model.DeviceUsageData{
			ID:       device.ID,
			Location: device.Location,
			Usage:    deviceTotal,
		}

		groupTotal += deviceTotal
	}

	result := make([]*model.DeviceUsageData, 0, len(deviceMap))
	for _, data := range deviceMap {
		if groupTotal > 0 {
			data.Usage = (data.Usage / groupTotal) * 100
		} else {
			data.Usage = 0.0
		}
		result = append(result, data)
	}

	return result, nil
}

// WaterUsages is the resolver for the waterUsages field.
func (r *queryResolver) WaterUsages(ctx context.Context) ([]*model.WaterUsage, error) {
	var usages []models.WaterUsage
	if err := config.DB.Preload("Device").Find(&usages).Error; err != nil {
		return nil, err
	}

	var result []*model.WaterUsage
	for _, u := range usages {
		var group models.UserGroup
		if err := config.DB.First(&group, u.Device.UserGroupID).Error; err != nil {
			return nil, fmt.Errorf("failed to fetch user group for device %s: %w", u.Device.ID, err)
		}

		result = append(result, &model.WaterUsage{
			FlowRate:   u.FlowRate,
			TotalUsage: u.TotalUsage,
			RecordedAt: u.RecordedAt,
			Device: &model.Device{
				ID:          u.Device.ID,
				Name:        u.Device.Name,
				Location:    u.Device.Location,
				CreatedAt:   u.Device.CreatedAt,
				WaterUsages: []*model.WaterUsage{},
				UserGroup: &model.UserGroup{
					ID:        strconv.Itoa(int(group.ID)),
					Name:      group.Name,
					CreatedAt: group.CreatedAt,
					Devices:   []*model.Device{},
					Users:     []*model.UserGroupMember{},
				},
			},
		})
	}
	return result, nil
}

// WaterUsagesData is the resolver for the waterUsagesData field.
func (r *queryResolver) WaterUsagesData(ctx context.Context, deviceID string, timeFilter string) (model.WaterData, error) {
	start, end, err := utils.GetTimeRange(timeFilter, time.Now())
	if err != nil {
		return nil, fmt.Errorf("invalid time range: %w", err)
	}

	var dbResults []models.WaterUsage
	err = config.DB.
		Preload("Device.UserGroup").
		Where("device_id = ? AND recorded_at BETWEEN ? AND ?", deviceID, start, end).
		Order("recorded_at").
		Find(&dbResults).Error

	if err != nil {
		return nil, fmt.Errorf("database error: %w", err)
	}

	gqlData := make([]*model.WaterUsage, len(dbResults))
	for i, wu := range dbResults {
		gqlData[i] = utils.ConvertToGQLWaterUsage(wu)
	}

	switch timeFilter {
	case "1d":
		return &model.WaterUsageList{Data: gqlData}, nil
	case "1w":
		dailyData := utils.ProcessWeeklyData(gqlData)
		return &model.DailyDataList{Data: dailyData}, nil
	case "1m":
		return utils.ProcessMonthlyData(gqlData), nil
	case "1y":
		return utils.ProcessYearlyData(gqlData), nil
	default:
		return nil, fmt.Errorf("unsupported time filter: %s", timeFilter)
	}
}

// DeepSeekAnalysis is the resolver for the deepSeekAnalysis field.
func (r *queryResolver) DeepSeekAnalysis(ctx context.Context, userID int32) (*model.DeepSeekResponse, error) {
	water, err := utils.GetUserUsageData(uint(userID))
	if err != nil {
		return nil, err
	}

	usage := map[string]interface{}{
		"waterUsage": water,
	}
	jsonData, err := json.Marshal(usage)
	if err != nil {
		return nil, err
	}

	analysis, err := utils.AnalyzeUsageData(string(jsonData))
	if err != nil {
		return nil, err
	}

	return &model.DeepSeekResponse{Analysis: &analysis}, nil
}

func (r *queryResolver) GroupAiAnalysis(ctx context.Context, groupID int32) (*model.DeepSeekResponse, error) {
	water, err := utils.GetGroupUsageData(uint(groupID))
	if err != nil {
		return nil, err
	}

	usage := map[string]interface{}{
		"waterUsage": water,
	}
	jsonData, err := json.Marshal(usage)
	if err != nil {
		return nil, err
	}

	analysis, err := utils.AnalyzeUsageData(string(jsonData))
	if err != nil {
		return nil, err
	}

	return &model.DeepSeekResponse{Analysis: &analysis}, nil
}

// Notifications is the resolver for the notifications field.
func (r *queryResolver) Notifications(ctx context.Context, userId int32) ([]*model.Notification, error) {

	var userGroupIDs []uint
	if err := config.DB.Model(&models.UserGroupMember{}).
		Where("user_id = ?", uint(userId)).
		Pluck("user_group_id", &userGroupIDs).Error; err != nil {
		return nil, err
	}

	if len(userGroupIDs) == 0 {
		return []*model.Notification{}, nil
	}

	var devices []models.Device
	if err := config.DB.
		Preload("UserGroup").
		Where("user_group_id IN ?", userGroupIDs).
		Find(&devices).Error; err != nil {
		return nil, err
	}

	now := time.Now()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	yesterdayStart := todayStart.Add(-24 * time.Hour)

	var notifications []*model.Notification

	for _, device := range devices {
		var todayTotal float64
		if err := config.DB.Model(&models.WaterUsage{}).
			Select("COALESCE(SUM(total_usage), 0)").
			Where("device_id = ? AND recorded_at >= ? AND recorded_at < ?",
				device.ID,
				todayStart,
				todayStart.Add(24*time.Hour),
			).
			Scan(&todayTotal).Error; err != nil {
			return nil, err
		}

		var yesterdayTotal float64
		if err := config.DB.Model(&models.WaterUsage{}).
			Select("COALESCE(SUM(total_usage), 0)").
			Where("device_id = ? AND recorded_at >= ? AND recorded_at < ?",
				device.ID,
				yesterdayStart,
				todayStart,
			).
			Scan(&yesterdayTotal).Error; err != nil {
			return nil, err
		}

		if yesterdayTotal == 0 && todayTotal == 0 {
			continue
		}

		groupName := device.UserGroup.Name
		deviceName := device.Name
		location := device.Location

		var title string
		var message string
		change := todayTotal - yesterdayTotal

		title = fmt.Sprintf("%s | %s | %s", groupName, deviceName, location)

		var percentChange float64
		if yesterdayTotal == 0 {
			if todayTotal == 0 {
				percentChange = 0
			} else {
				percentChange = 100
			}
		} else {
			percentChange = (change / yesterdayTotal) * 100
		}

		if percentChange > 0 {
			message = fmt.Sprintf(
				"Penggunaan air meningkat sebesar %.2f%% (%.2fL → %.2fL). Coba periksa apakah ada keran yang lupa dimatikan atau penggunaan berlebih yang tidak biasa.",
				percentChange,
				yesterdayTotal,
				todayTotal)
		} else if percentChange < 0 {
			message = fmt.Sprintf(
				"Bagus! Penggunaan air menurun sebesar %.2f%% (%.2fL → %.2fL). Terus pertahankan kebiasaan hemat air!",
				math.Abs(percentChange),
				yesterdayTotal,
				todayTotal)
		} else {
			message = fmt.Sprintf(
				"Penggunaan air tetap sama (%.2fL) seperti kemarin. Stabil, tapi bisa lebih hemat lagi jika memungkinkan.",
				todayTotal)
		}

		notifications = append(notifications, &model.Notification{
			ID:        fmt.Sprintf("usage-%s-%d", device.ID, now.Unix()),
			Title:     title,
			Message:   message,
			CreatedAt: time.Now(),
			Device:    utils.ConvertToGQLDevice(device),
		})
	}

	return notifications, nil
}

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }

// !!! WARNING !!!
// The code below was going to be deleted when updating resolvers. It has been copied here so you have
// one last chance to move it out of harms way if you want. There are two reasons this happens:
//   - When renaming or deleting a resolver the old code will be put in here. You can safely delete
//     it when you're done.
//   - You have helper methods in this file. Move them out to keep these resolver files clean.
