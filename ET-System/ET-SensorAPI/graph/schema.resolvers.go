package graph

// THIS CODE WILL BE UPDATED WITH SCHEMA CHANGES. PREVIOUS IMPLEMENTATION FOR SCHEMA CHANGES WILL BE KEPT IN THE COMMENT SECTION. IMPLEMENTATION FOR UNCHANGED SCHEMA WILL BE KEPT.

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/graph/model"
	"ET-SensorAPI/models"
	"ET-SensorAPI/utils"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
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
		return nil, errors.New("failed to verify email")
	}

	groupIDs := utils.FetchUserGroupIDs(user.ID)
	var groups []*model.UserGroup
	for _, id := range groupIDs {
		groups = append(groups, &model.UserGroup{ID: strconv.Itoa(int(id))})
	}

	return &model.AuthPayload{
		User: &model.User{
			ID:          strconv.Itoa(int(user.ID)),
			DisplayName: &user.DisplayName, // Fix: string to *string
			Email:       user.Email,
			Verified:    user.Verified,
			CreatedAt:   user.CreatedAt,
			Groups:      groups,
		},
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
	var user models.User
	if err := config.DB.Where("email = ?", receiverEmail).First(&user).Error; err != nil {
		return nil, errors.New("user not found")
	}

	var group models.UserGroup
	if err := config.DB.First(&group, userGroupID).Error; err != nil {
		return nil, errors.New("group not found")
	}

	var count int64
	config.DB.Model(&models.UserGroupMember{}).Where("user_group_id = ?", group.ID).Count(&count)
	if count >= 4 {
		return nil, errors.New("user group cannot have more than 4 users")
	}

	membership := models.UserGroupMember{UserID: user.ID, UserGroupID: group.ID}
	if err := config.DB.Create(&membership).Error; err != nil {
		return nil, errors.New("failed to assign user to group")
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

	if user.Verified {
		return nil, errors.New("email is already verified")
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
	if groupName == "" {
		return nil, errors.New("group name cannot be empty")
	}
	if userID <= 0 {
		return nil, errors.New("invalid user ID")
	}

	var user models.User
	if err := config.DB.First(&user, uint(userID)).Error; err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}

	tx := config.DB.Begin()
	defer func() {
		if r := recover(); r != nil || tx.Error != nil {
			tx.Rollback()
		}
	}()

	group := models.UserGroup{Name: groupName}
	if err := tx.Create(&group).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to create user group: %w", err)
	}

	member := models.UserGroupMember{
		UserID:      uint(userID),
		UserGroupID: group.ID,
	}
	if err := tx.Create(&member).Error; err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("failed to add user to group: %w", err)
	}

	if err := tx.Commit().Error; err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	var members []models.UserGroupMember
	if err := config.DB.Where("user_group_id = ?", group.ID).Find(&members).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch group members: %w", err)
	}

	userIDs := make([]uint, 0, len(members))
	for _, member := range members {
		userIDs = append(userIDs, member.UserID)
	}
	var users []models.User
	if len(userIDs) > 0 {
		if err := config.DB.Where("id IN ?", userIDs).Find(&users).Error; err != nil {
			return nil, fmt.Errorf("failed to fetch users: %w", err)
		}
	}

	graphqlUsers := make([]*model.User, 0, len(users))
	for _, u := range users {
		displayName := &u.DisplayName
		graphqlUsers = append(graphqlUsers, &model.User{
			ID:          strconv.Itoa(int(u.ID)),
			Email:       u.Email,
			DisplayName: displayName,
			Verified:    u.Verified,
			CreatedAt:   u.CreatedAt,
		})
	}

	// Fetch devices (new group should have none)
	var groupWithDevices models.UserGroup
	if err := config.DB.Preload("Devices").First(&groupWithDevices, group.ID).Error; err != nil {
		return nil, fmt.Errorf("failed to reload user group: %w", err)
	}

	return &model.UserGroup{
		ID:        strconv.Itoa(int(group.ID)),
		Name:      group.Name,
		CreatedAt: group.CreatedAt,
		Devices:   []*model.Device{},
		Users:     graphqlUsers,
	}, nil
}

// AddDeviceToUserGroup is the resolver for the addDeviceToUserGroup field.
func (r *mutationResolver) AddDeviceToUserGroup(ctx context.Context, deviceID string, deviceName string, userGroupID int32, location string) (*model.UserGroup, error) {
	if deviceID == "" || deviceName == "" || userGroupID <= 0 {
		return nil, errors.New("deviceID, deviceName, and userGroupID are required")
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
	if err := config.DB.Where("user_group_id = ?", group.ID).Find(&members).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch group members: %w", err)
	}

	userIDs := make([]uint, 0, len(members))
	for _, member := range members {
		userIDs = append(userIDs, member.UserID)
	}
	var users []models.User
	if len(userIDs) > 0 {
		if err := config.DB.Where("id IN ?", userIDs).Find(&users).Error; err != nil {
			return nil, fmt.Errorf("failed to fetch users: %w", err)
		}
	}

	devices := make([]*model.Device, 0, len(group.Devices))
	for _, d := range group.Devices {
		devices = append(devices, &model.Device{
			ID: d.ID,
			UserGroup: &model.UserGroup{
				ID:        strconv.Itoa(int(group.ID)),
				Name:      group.Name,
				CreatedAt: group.CreatedAt,
				Devices:   []*model.Device{},
				Users:     []*model.User{},
			},
			Name:        d.Name,
			Location:    d.Location,
			CreatedAt:   d.CreatedAt,
			WaterUsages: []*model.WaterUsage{},
		})
	}

	graphqlUsers := make([]*model.User, 0, len(users))
	for _, u := range users {
		displayName := &u.DisplayName
		graphqlUsers = append(graphqlUsers, &model.User{
			ID:          strconv.Itoa(int(u.ID)),
			Email:       u.Email,
			DisplayName: displayName,
			Verified:    u.Verified,
			CreatedAt:   u.CreatedAt,
		})
	}

	return &model.UserGroup{
		ID:        strconv.Itoa(int(group.ID)),
		Name:      group.Name,
		CreatedAt: group.CreatedAt,
		Devices:   devices,
		Users:     graphqlUsers,
	}, nil
}

// OauthLogin is the resolver for the oauthLogin field.
func (r *mutationResolver) OauthLogin(ctx context.Context, provider model.OAuthProvider, token string) (*model.AuthPayload, error) {
	if token == "" {
		return nil, errors.New("token is required")
	}

	var user models.User
	var email, displayName, providerID string
	var err error

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

		providerID = payload.Claims["sub"].(string)
		email = payload.Claims["email"].(string)
		displayName = payload.Claims["name"].(string)

	case model.OAuthProviderApple:
		claims, err := utils.ValidateAppleToken(token)
		if err != nil {
			return nil, fmt.Errorf("invalid Apple token: %w", err)
		}

		providerID = claims["sub"].(string)
		if emailVal, ok := claims["email"].(string); ok {
			email = emailVal
		}

	default:
		return nil, errors.New("unsupported provider")
	}

	err = config.DB.Where("provider = ? AND provider_id = ?", providerStr, providerID).First(&user).Error
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("database error: %w", err)
	}

	if errors.Is(err, gorm.ErrRecordNotFound) && email != "" {
		err = config.DB.Where("email = ?", email).First(&user).Error
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("database error: %w", err)
		}
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
	} else {
		user.Provider = providerStr
		user.ProviderID = providerID

		if email != "" && user.Email != email {
			var existingUser models.User
			if err := config.DB.Where("email = ?", email).First(&existingUser).Error; err == nil && existingUser.ID != user.ID {
				return nil, errors.New("email already registered")
			}
			user.Email = email
		}

		if displayName != "" && user.DisplayName != displayName {
			user.DisplayName = displayName
		}

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
	var groups []*model.UserGroup
	for _, id := range groupIDs {
		groups = append(groups, &model.UserGroup{ID: strconv.Itoa(int(id))})
	}

	gqlUser := &model.User{
		ID:          strconv.Itoa(int(user.ID)),
		Email:       user.Email,
		DisplayName: &user.DisplayName,
		Verified:    user.Verified,
		CreatedAt:   user.CreatedAt,
		Groups:      groups,
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

// Users is the resolver for the users field.
func (r *queryResolver) Users(ctx context.Context) ([]*model.User, error) {
	var users []models.User
	if err := config.DB.Find(&users).Error; err != nil {
		return nil, err
	}

	var result []*model.User
	for _, u := range users {
		groupIDs := utils.FetchUserGroupIDs(u.ID)
		var groups []*model.UserGroup
		for _, id := range groupIDs {
			groups = append(groups, &model.UserGroup{ID: strconv.Itoa(int(id))})
		}

		displayName := &u.DisplayName
		result = append(result, &model.User{
			ID:          strconv.Itoa(int(u.ID)),
			Email:       u.Email,
			DisplayName: displayName,
			Verified:    u.Verified,
			CreatedAt:   u.CreatedAt,
			Groups:      groups,
		})
	}
	return result, nil
}

// UserGroups is the resolver for the userGroups field.
func (r *queryResolver) UserGroups(ctx context.Context) ([]*model.UserGroup, error) {
	var groups []models.UserGroup
	if err := config.DB.Preload("Devices.WaterUsages").Find(&groups).Error; err != nil {
		return nil, err
	}

	var result []*model.UserGroup
	for _, g := range groups {
		users := utils.FetchGroupUsers(g.ID)
		var devices []*model.Device
		for _, d := range g.Devices {
			var waterUsages []*model.WaterUsage
			for _, wu := range d.WaterUsages {
				waterUsages = append(waterUsages, &model.WaterUsage{
					FlowRate:   wu.FlowRate,
					TotalUsage: wu.TotalUsage,
					RecordedAt: wu.RecordedAt,
				})
			}

			devices = append(devices, &model.Device{
				ID:          d.ID,
				Name:        d.Name,
				Location:    d.Location,
				CreatedAt:   d.CreatedAt,
				WaterUsages: waterUsages,
				UserGroup: &model.UserGroup{
					ID:        strconv.Itoa(int(g.ID)),
					Name:      g.Name,
					CreatedAt: g.CreatedAt,
					Devices:   []*model.Device{},
					Users:     []*model.User{},
				},
			})
		}
		result = append(result, &model.UserGroup{
			ID:        strconv.Itoa(int(g.ID)),
			Name:      g.Name,
			CreatedAt: g.CreatedAt,
			Devices:   devices,
			Users:     users,
		})
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
				Users:     []*model.User{},
			},
		})
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
					Users:     []*model.User{},
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
		gqlData[i] = convertToGQLWaterUsage(wu)
	}

	switch timeFilter {
	case "1d":
		return &model.WaterUsageList{Data: gqlData}, nil
	case "1w":
		dailyData := processWeeklyData(gqlData)
		return &model.DailyDataList{Data: dailyData}, nil
	case "1m":
		return processMonthlyData(gqlData), nil
	case "1y":
		return processYearlyData(gqlData), nil
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

// Mutation returns MutationResolver implementation.
func (r *Resolver) Mutation() MutationResolver { return &mutationResolver{r} }

// Query returns QueryResolver implementation.
func (r *Resolver) Query() QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }

// !!! WARNING !!!
// The code below was going to be deleted when updating resolvers. It has been copied here so you have
// one last chance to move it out of harms way if you want. There are two reasons this happens:
//  - When renaming or deleting a resolver the old code will be put in here. You can safely delete
//    it when you're done.
//  - You have helper methods in this file. Move them out to keep these resolver files clean.

func convertDeviceToGQL(d models.Device) *model.Device {
	return &model.Device{
		ID:       d.ID,
		Name:     d.Name,
		Location: d.Location,
		UserGroup: &model.UserGroup{
			ID:        fmt.Sprintf("%d", d.UserGroupID),
			Name:      d.UserGroup.Name,
			CreatedAt: d.UserGroup.CreatedAt,
			Location:  d.UserGroup.Location,
		},
	}
}

func convertToGQLWaterUsage(wu models.WaterUsage) *model.WaterUsage {
	return &model.WaterUsage{
		ID:         fmt.Sprintf("%d", wu.ID),
		FlowRate:   wu.FlowRate,
		TotalUsage: wu.TotalUsage,
		RecordedAt: wu.RecordedAt,
		Device: &model.Device{
			ID:       wu.Device.ID,
			Name:     wu.Device.Name,
			Location: wu.Device.Location,
			UserGroup: &model.UserGroup{
				ID:   fmt.Sprintf("%d", wu.Device.UserGroupID),
				Name: wu.Device.UserGroup.Name,
			},
		},
	}
}

func processWeeklyData(data []*model.WaterUsage) []*model.DailyData {
	dailyMap := make(map[string]*model.DailyData)

	for _, entry := range data {
		date := entry.RecordedAt.Format("2006-01-02")
		if _, exists := dailyMap[date]; !exists {
			dailyMap[date] = &model.DailyData{
				Date: entry.RecordedAt.Format("Mon, 02 Jan"),
			}
		}
		dailyMap[date].Hourly = append(dailyMap[date].Hourly, entry)
		dailyMap[date].TotalUsage += entry.TotalUsage
	}

	var result []*model.DailyData
	for _, day := range dailyMap {
		day.AvgFlow = calculateAverageFlow(day.Hourly)
		result = append(result, day)
	}

	sort.Slice(result, func(i, j int) bool {
		t1, _ := time.Parse("2006-01-02", result[i].Date)
		t2, _ := time.Parse("2006-01-02", result[j].Date)
		return t1.Before(t2)
	})

	return result
}

func processMonthlyData(data []*model.WaterUsage) *model.MonthlyData {
	monthly := &model.MonthlyData{
		Month: data[0].RecordedAt.Format("January 2006"),
	}
	dailyMap := make(map[string]*model.DailyData)

	for _, entry := range data {
		date := entry.RecordedAt.Format("2006-01-02")
		if _, exists := dailyMap[date]; !exists {
			dailyMap[date] = &model.DailyData{
				Date: entry.RecordedAt.Format("02 Jan"),
			}
		}
		dailyMap[date].Hourly = append(dailyMap[date].Hourly, entry)
		dailyMap[date].TotalUsage += entry.TotalUsage
		monthly.TotalUsage += entry.TotalUsage
	}

	var days []*model.DailyData
	for _, day := range dailyMap {
		day.AvgFlow = calculateAverageFlow(day.Hourly)
		days = append(days, day)
	}
	monthly.Days = days
	monthly.AvgFlow = calculateAverageFlow(data)

	return monthly
}

func processYearlyData(data []*model.WaterUsage) *model.YearlyData {
	yearly := &model.YearlyData{
		Year: data[0].RecordedAt.Format("2006"),
	}
	monthlyMap := make(map[string]*model.MonthlyData)

	for _, entry := range data {
		monthKey := entry.RecordedAt.Format("2006-01")
		if _, exists := monthlyMap[monthKey]; !exists {
			monthlyMap[monthKey] = &model.MonthlyData{
				Month: entry.RecordedAt.Format("January"),
			}
		}
		month := monthlyMap[monthKey]

		date := entry.RecordedAt.Format("2006-01-02")
		var day *model.DailyData
		for _, d := range month.Days {
			if d.Date == date {
				day = d
				break
			}
		}
		if day == nil {
			day = &model.DailyData{Date: entry.RecordedAt.Format("02 Jan")}
			month.Days = append(month.Days, day)
		}
		day.Hourly = append(day.Hourly, entry)
		day.TotalUsage += entry.TotalUsage
		month.TotalUsage += entry.TotalUsage
		yearly.TotalUsage += entry.TotalUsage
	}

	var months []*model.MonthlyData
	for _, month := range monthlyMap {
		month.AvgFlow = calculateAverageFlowForMonth(month.Days)
		months = append(months, month)
	}
	yearly.Months = months
	yearly.AvgFlow = calculateAverageFlow(data)

	return yearly
}

func calculateAverageFlow(entries []*model.WaterUsage) float64 {
	total := 0.0
	for _, entry := range entries {
		total += entry.FlowRate
	}
	if len(entries) == 0 {
		return 0
	}
	return total / float64(len(entries))
}

func calculateAverageFlowForMonth(days []*model.DailyData) float64 {
	total := 0.0
	count := 0
	for _, day := range days {
		total += day.AvgFlow
		count++
	}
	if count == 0 {
		return 0
	}
	return total / float64(count)
}
