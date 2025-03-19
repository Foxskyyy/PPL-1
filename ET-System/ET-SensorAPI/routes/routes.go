package routes

import (
	"ET-SensorAPI/controllers"

	"github.com/gin-gonic/gin"
)

func SetupRouter(r *gin.Engine) {
	api := r.Group("/api/v1")
	{
		// User Management
		userGroup := api.Group("/users")
		{
			userGroup.POST("/", controllers.CreateUser)
			userGroup.GET("/", controllers.GetUsers)
			userGroup.PUT("/:user_id/group", controllers.AssignUserToGroup)
			userGroup.POST("/data", controllers.GetUserData)
		}

		// Authentication & Email Verification
		authGroup := api.Group("/auth")
		{
			authGroup.POST("/register", controllers.Register)
			authGroup.POST("/verify", controllers.VerifyEmail)
			authGroup.POST("/login", controllers.Login)
		}

		// User Groups
		group := api.Group("/user-groups")
		{
			group.POST("/", controllers.CreateUserGroup)
			group.GET("/", controllers.GetUserGroups)
			group.POST("/members", controllers.AddUserToGroup)
		}

		// Devices
		deviceGroup := api.Group("/devices")
		{
			deviceGroup.POST("/", controllers.CreateDevice)
			deviceGroup.GET("/", controllers.GetDevices)
		}

		// Water Usage
		waterGroup := api.Group("/water-usage")
		{
			waterGroup.POST("/", controllers.CreateWaterUsage)
			waterGroup.GET("/", controllers.GetWaterUsage)
		}

		// Electricity Usage
		electricityGroup := api.Group("/electricity-usage")
		{
			electricityGroup.POST("/", controllers.CreateElectricityUsage)
			electricityGroup.GET("/", controllers.GetElectricityUsage)
		}
	}
}
