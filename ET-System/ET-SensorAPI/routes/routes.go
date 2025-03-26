package routes

import (
	"ET-SensorAPI/controllers"

	"github.com/gin-gonic/gin"
)

func SetupRouter(r *gin.Engine) {
	api := r.Group("/api/v1")
	{

		userGroup := api.Group("/users")
		{
			userGroup.POST("/", controllers.CreateUser)
			userGroup.GET("/", controllers.GetUsers)
			userGroup.PUT("/:user_id/group", controllers.AssignUserToGroup)
			userGroup.POST("/data", controllers.GetUserData)
		}

		authGroup := api.Group("/auth")
		{
			authGroup.POST("/register", controllers.Register)
			authGroup.POST("/verify", controllers.VerifyEmail)
			authGroup.POST("/login", controllers.Login)
		}

		group := api.Group("/user-groups")
		{
			group.POST("/", controllers.CreateUserGroup)
			group.GET("/", controllers.GetDeviceGroups)
			group.POST("/members", controllers.AddUserToGroup)
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

		electricityGroup := api.Group("/electricity-usage")
		{
			electricityGroup.POST("/", controllers.CreateElectricityUsage)
			electricityGroup.GET("/", controllers.GetElectricityUsage)
		}

		logsGroup := api.Group("/device-logs")
		{
			logsGroup.GET("/group/:group_id", controllers.GetDeviceLogs)
		}
	}
}
