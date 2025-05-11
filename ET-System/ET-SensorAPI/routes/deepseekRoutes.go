package routes

import (
	"ET-SensorAPI/config"
	"ET-SensorAPI/controllers"

	"github.com/gin-gonic/gin"
)

func SetupDeepSeekRoutes(router *gin.Engine) {
	deepseekGroup := router.Group("/deepseek")
	{
		deepseekGroup.GET("/analysis", func(c *gin.Context) {
			controllers.GetUsageAnalysis(config.DB, c.Writer, c.Request)
		})
	}
}
