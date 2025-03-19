package controllers

import (
	"ET-SensorAPI/models"
	"ET-SensorAPI/utils"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"gorm.io/gorm"
)

func GetUsageAnalysis(db *gorm.DB, w http.ResponseWriter, r *http.Request) {
	var usage []models.WaterUsage
	startDate := time.Now().AddDate(0, -3, 0)
	db.Where("recorded_at >= ?", startDate).Find(&usage)

	if len(usage) == 0 {
		http.Error(w, "No usage data found", http.StatusNotFound)
		return
	}

	usageData, _ := json.Marshal(usage)
	deepSeekOutput, err := utils.AnalyzeUsageData(string(usageData))
	if err != nil {
		http.Error(w, fmt.Sprintf("Ollama error: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"analysis": deepSeekOutput})
}
