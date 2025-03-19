package graphql

import (
	"encoding/json"
	"fmt"

	"ET-SensorAPI/config"
	"ET-SensorAPI/models"
	"ET-SensorAPI/utils"

	"github.com/graphql-go/graphql"
)

var userType = graphql.NewObject(
	graphql.ObjectConfig{
		Name: "User",
		Fields: graphql.Fields{
			"id":       &graphql.Field{Type: graphql.Int},
			"username": &graphql.Field{Type: graphql.String},
			"email":    &graphql.Field{Type: graphql.String},
			"groups": &graphql.Field{
				Type: graphql.NewList(graphql.Int),
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					user, ok := p.Source.(models.User)
					if !ok {
						return nil, nil
					}

					var memberships []models.UserGroupMember
					config.DB.Where("user_id = ?", user.ID).Find(&memberships)

					var groupIDs []uint
					for _, m := range memberships {
						groupIDs = append(groupIDs, m.UserGroupID)
					}

					return groupIDs, nil
				},
			},
		},
	},
)

var userGroupType = graphql.NewObject(
	graphql.ObjectConfig{
		Name: "UserGroup",
		Fields: graphql.Fields{
			"id":   &graphql.Field{Type: graphql.Int},
			"name": &graphql.Field{Type: graphql.String},
			"users": &graphql.Field{
				Type: graphql.NewList(userType),
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					group, ok := p.Source.(models.UserGroup)
					if !ok {
						return nil, nil
					}

					var memberships []models.UserGroupMember
					config.DB.Where("user_group_id = ?", group.ID).Find(&memberships)

					var users []models.User
					for _, m := range memberships {
						var user models.User
						if err := config.DB.First(&user, m.UserID).Error; err == nil {
							users = append(users, user)
						}
					}

					return users, nil
				},
			},
		},
	},
)

var deepSeekResponseType = graphql.NewObject(
	graphql.ObjectConfig{
		Name: "DeepSeekResponse",
		Fields: graphql.Fields{
			"analysis": &graphql.Field{Type: graphql.String},
			"advice":   &graphql.Field{Type: graphql.String},
		},
	},
)

var queryType = graphql.NewObject(
	graphql.ObjectConfig{
		Name: "Query",
		Fields: graphql.Fields{
			"users": &graphql.Field{
				Type: graphql.NewList(userType),
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					var users []models.User
					config.DB.Find(&users)
					return users, nil
				},
			},
			"userGroups": &graphql.Field{
				Type: graphql.NewList(userGroupType),
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					var groups []models.UserGroup
					config.DB.Find(&groups)
					return groups, nil
				},
			},
			"deepSeekAnalysis": &graphql.Field{
				Type: deepSeekResponseType,
				Args: graphql.FieldConfigArgument{
					"userID": &graphql.ArgumentConfig{Type: graphql.Int},
				},
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					userID, ok := p.Args["userID"].(int)
					if !ok {
						return nil, fmt.Errorf("userID must be an integer")
					}

					waterUsage, electricityUsage, err := utils.GetUserUsageData(uint(userID))
					if err != nil {
						return nil, err
					}

					usageData := map[string]interface{}{
						"waterUsage":       waterUsage,
						"electricityUsage": electricityUsage,
					}

					usageDataJSON, err := json.Marshal(usageData)
					if err != nil {
						return nil, fmt.Errorf("error marshaling usage data: %v", err)
					}

					analysis, err := utils.AnalyzeUsageData(string(usageDataJSON))
					if err != nil {
						return nil, err
					}

					return map[string]interface{}{
						"analysis": analysis,
					}, nil
				},
			},
		},
	},
)

var mutationType = graphql.NewObject(
	graphql.ObjectConfig{
		Name: "Mutation",
		Fields: graphql.Fields{
			"login": &graphql.Field{
				Type: userType,
				Args: graphql.FieldConfigArgument{
					"email":    &graphql.ArgumentConfig{Type: graphql.String},
					"password": &graphql.ArgumentConfig{Type: graphql.String},
				},
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					email, _ := p.Args["email"].(string)
					password, _ := p.Args["password"].(string)

					user, err := utils.AuthenticateUser(email, password)
					if err != nil {
						return nil, err
					}

					return user, nil
				},
			},
			"assignUserToGroup": &graphql.Field{
				Type: graphql.String,
				Args: graphql.FieldConfigArgument{
					"userID":      &graphql.ArgumentConfig{Type: graphql.Int},
					"userGroupID": &graphql.ArgumentConfig{Type: graphql.Int},
				},
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					userID, userOK := p.Args["userID"].(int)
					groupID, groupOK := p.Args["userGroupID"].(int)

					if !userOK || !groupOK {
						return nil, fmt.Errorf("Invalid input parameters")
					}

					var user models.User
					if err := config.DB.First(&user, userID).Error; err != nil {
						return nil, fmt.Errorf("User not found")
					}

					var group models.UserGroup
					if err := config.DB.First(&group, groupID).Error; err != nil {
						return nil, fmt.Errorf("User group not found")
					}

					var count int64
					config.DB.Model(&models.UserGroupMember{}).Where("user_group_id = ?", groupID).Count(&count)
					if count >= 4 {
						return nil, fmt.Errorf("User group cannot have more than 4 users")
					}

					userGroupMember := models.UserGroupMember{
						UserID:      uint(userID),
						UserGroupID: uint(groupID),
					}

					if err := config.DB.Create(&userGroupMember).Error; err != nil {
						return nil, fmt.Errorf("Failed to assign user to group")
					}

					return "User assigned to group successfully", nil
				},
			},
			"register": &graphql.Field{
				Type: graphql.String,
				Args: graphql.FieldConfigArgument{
					"username": &graphql.ArgumentConfig{Type: graphql.String},
					"email":    &graphql.ArgumentConfig{Type: graphql.String},
					"password": &graphql.ArgumentConfig{Type: graphql.String},
				},
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					username, _ := p.Args["username"].(string)
					email, _ := p.Args["email"].(string)
					password, _ := p.Args["password"].(string)

					var existingUser models.User
					if err := config.DB.Where("email = ?", email).First(&existingUser).Error; err == nil {
						return nil, fmt.Errorf("Email already registered")
					}

					hashedPassword, err := utils.HashPassword(password)
					if err != nil {
						return nil, fmt.Errorf("Failed to hash password")
					}

					token, _ := utils.GenerateOTP()

					newUser := models.User{
						Username:    username,
						Email:       email,
						Password:    hashedPassword,
						Verified:    false,
						VerifyToken: token,
					}

					if err := config.DB.Create(&newUser).Error; err != nil {
						return nil, fmt.Errorf("Failed to create user")
					}

					if err := utils.SendVerificationEmail(email, token); err != nil {
						return nil, fmt.Errorf("Failed to send verification email")
					}

					return "Registration successful. Please check your email for verification.", nil
				},
			},

			"verifyEmail": &graphql.Field{
				Type: graphql.String,
				Args: graphql.FieldConfigArgument{
					"token": &graphql.ArgumentConfig{Type: graphql.String},
				},
				Resolve: func(p graphql.ResolveParams) (interface{}, error) {
					token, _ := p.Args["token"].(string)

					var user models.User
					if err := config.DB.Where("verify_token = ?", token).First(&user).Error; err != nil {
						return nil, fmt.Errorf("Invalid or expired token")
					}

					user.Verified = true
					user.VerifyToken = ""
					if err := config.DB.Save(&user).Error; err != nil {
						return nil, fmt.Errorf("Failed to verify email")
					}

					return "Email verified successfully.", nil
				},
			},
		},
	},
)

var Schema, _ = graphql.NewSchema(
	graphql.SchemaConfig{
		Query:    queryType,
		Mutation: mutationType,
	},
)
