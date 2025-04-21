package graph

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/graph/model"
	"ET-SensorAPI/utils"
	"context"
	"errors"
	"strconv"
)

// Login is the resolver for the login field.
func (r *mutationResolver) Login(ctx context.Context, email string, password string) (*model.AuthPayload, error) {

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
			DisplayName: &user.DisplayName,
			Email:       user.Email,
			Verified:    user.Verified,
			CreatedAt:   user.CreatedAt,
			Groups:      groups,
		},
		Token: token,
	}, nil
}
