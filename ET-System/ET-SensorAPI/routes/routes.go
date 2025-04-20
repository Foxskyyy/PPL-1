package routes

import (
	"ET-SensorAPI/controllers"

	"github.com/gin-gonic/gin"
)

func SetupRouter(r *gin.Engine) {
	api := r.Group("/api/v1")
	{

		userGroup := api.Group("/user-groups")
		{
			userGroup.POST("/", controllers.CreateUserGroup)
			userGroup.GET("/", controllers.GetDeviceGroups)
			userGroup.PUT("/:user_id/group", controllers.AssignUserToGroup)
			userGroup.GET("/:uid/groups", controllers.GetUserGroupsByUserID)
		}

		authGroup := api.Group("/auth")
		{
			authGroup.POST("/register", controllers.Register)
			authGroup.POST("/verify", controllers.VerifyEmail)
			authGroup.POST("/login", controllers.Login)
		}

		users := api.Group("/users")
		{
			users.POST("/", controllers.CreateUser)
			users.GET("/", controllers.GetUsers)
			users.POST("/data", controllers.GetUserData)
			users.POST("/members", controllers.AddUserToGroup)
		}

		deviceGroup := api.Group("/devices")
		{
			deviceGroup.POST("/", controllers.CreateDevice)
			deviceGroup.GET("/", controllers.GetDevices)
			deviceGroup.GET("/group/:group_id", controllers.GetDevicesByGroup)
		}

		waterGroup := api.Group("/water-usage")
		{
			waterGroup.POST("/", controllers.CreateWaterUsage)
			waterGroup.GET("/", controllers.GetWaterUsage)
			waterGroup.GET("/device/:device_id", controllers.GetDeviceWaterUsage)
		}

		logsGroup := api.Group("/device-logs")
		{
			logsGroup.GET("/group/:group_id", controllers.GetDeviceLogs)
		}
	}
}
