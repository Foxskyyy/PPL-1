package utils

import (
	"ET-SensorAPI/graph/model"
	"ET-SensorAPI/models"
	"fmt"
	"sort"
	"time"
)

type DailyData struct {
	Date       string              `json:"date"`
	Hourly     []*model.WaterUsage `json:"hourly"`
	TotalUsage float64             `json:"totalUsage"`
	AvgFlow    float64             `json:"avgFlow"`
}

type MonthlyData struct {
	Month      string       `json:"month"`
	Days       []*DailyData `json:"days"`
	TotalUsage float64      `json:"totalUsage"`
	AvgFlow    float64      `json:"avgFlow"`
}

type YearlyData struct {
	Year       string         `json:"year"`
	Months     []*MonthlyData `json:"months"`
	TotalUsage float64        `json:"totalUsage"`
	AvgFlow    float64        `json:"avgFlow"`
}

func GetTimeRange(filter string, now time.Time) (time.Time, time.Time, error) {
	now = now.UTC()
	switch filter {
	case "1d":
		return now.Truncate(24 * time.Hour), now.Add(24 * time.Hour), nil
	case "1w":
		start := now.AddDate(0, 0, -int(now.Weekday())+1)
		return start.Truncate(24 * time.Hour), start.AddDate(0, 0, 7), nil
	case "1m":
		start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
		return start, start.AddDate(0, 1, 0), nil
	case "1y":
		start := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
		return start, start.AddDate(1, 0, 0), nil
	default:
		return time.Time{}, time.Time{}, fmt.Errorf("invalid time filter: %s", filter)
	}
}

func ConvertToGQLDevice(d models.Device) *model.Device {
	return &model.Device{
		ID:        d.ID,
		Name:      d.Name,
		Location:  d.Location,
		CreatedAt: d.CreatedAt,
	}

}

func ConvertToGQLWaterUsage(wu models.WaterUsage) *model.WaterUsage {
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
func ProcessWeeklyData(data []*model.WaterUsage) []*model.DailyData {
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
		day.AvgFlow = CalculateAverageFlow(day.Hourly)
		result = append(result, day)
	}

	sort.Slice(result, func(i, j int) bool {
		t1, _ := time.Parse("2006-01-02", result[i].Date)
		t2, _ := time.Parse("2006-01-02", result[j].Date)
		return t1.Before(t2)
	})

	return result
}
func ProcessMonthlyData(data []*model.WaterUsage) *model.MonthlyData {
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
		day.AvgFlow = CalculateAverageFlow(day.Hourly)
		days = append(days, day)
	}
	monthly.Days = days
	monthly.AvgFlow = CalculateAverageFlow(data)

	return monthly
}
func ProcessYearlyData(data []*model.WaterUsage) *model.YearlyData {
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
		day.AvgFlow = CalculateAverageFlow(day.Hourly)
		month.TotalUsage += entry.TotalUsage
		yearly.TotalUsage += entry.TotalUsage
	}

	var months []*model.MonthlyData
	for _, month := range monthlyMap {
		month.AvgFlow = CalculateAverageFlowForMonth(month.Days)
		months = append(months, month)
	}
	yearly.Months = months
	yearly.AvgFlow = CalculateAverageFlow(data)

	return yearly
}
func CalculateAverageFlow(entries []*model.WaterUsage) float64 {
	total := 0.0
	for _, entry := range entries {
		total += entry.FlowRate
	}
	if len(entries) == 0 {
		return 0
	}
	return total / float64(len(entries))
}
func CalculateAverageFlowForMonth(days []*model.DailyData) float64 {
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
