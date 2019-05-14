package router

import (
	"fmt"
	"net/http"
	"sync"
	"time"
)

const (
	ForumCreate = "ForumCreate"
	ForumDetails = "ForumDetails"
	ForumCreateThread = "ForumCreateThread"
	ForumUsers = "ForumUsers"
	ForumThreads = "ForumThreads"
	PostDetails = "PostDetails"
	PostEdit = "PostEdit"
	ServiceClear = "ServiceClear"
	ServiceStatus = "ServiceStatus"
	ThreadCreatePost = "ThreadCreatePost"
	ThreadDetails = "ThreadDetails"
	ThreadUpdate = "ThreadUpdate"
	ThreadPosts = "ThreadPosts"
	ThreadVote = "ThreadVote"
	UserCreate = "UserCreate"
	UserProfile = "UserProfile"
	UserEditProfile = "UserEditProfile"
)

type Statistics struct {
	TotalRequests float64
	AverageTime   float64
}

var totalStats = make(map[string]Statistics)
var mu sync.Mutex

func init() {
	totalStats[ForumCreate] = Statistics{}
	totalStats[ForumDetails] = Statistics{}
	totalStats[ForumCreateThread] = Statistics{}
	totalStats[ForumUsers] = Statistics{}
	totalStats[ForumThreads] = Statistics{}
	totalStats[PostDetails] = Statistics{}
	totalStats[PostEdit] = Statistics{}
	totalStats[ServiceClear] = Statistics{}
	totalStats[ServiceStatus] = Statistics{}
	totalStats[ThreadCreatePost] = Statistics{}
	totalStats[ThreadDetails] = Statistics{}
	totalStats[ThreadUpdate] = Statistics{}
	totalStats[ThreadPosts] = Statistics{}
	totalStats[ThreadVote] = Statistics{}
	totalStats[UserCreate] = Statistics{}
	totalStats[UserProfile] = Statistics{}
	totalStats[UserEditProfile] = Statistics{}
}

func StartTransmitStats() {
	ticker := time.Tick(5 * time.Second)
	for _ = range ticker {
		for id, stats := range totalStats {
			fmt.Printf("%s - %d hits  %f sec \n", id, int(stats.TotalRequests), stats.AverageTime)
		}
		fmt.Println("*****")
	}
}

func MiddlewareLog(next http.HandlerFunc, id string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		timer := time.Now()
		next.ServeHTTP(w, r)
		requestTime := time.Since(timer)
		mu.Lock()
		stats := totalStats[id]
		stats.AverageTime = (stats.AverageTime * stats.TotalRequests + requestTime.Seconds()) / (stats.TotalRequests + 1)
		stats.TotalRequests++
		totalStats[id] = stats
		mu.Unlock()
	})
}

func MiddlewareBasicHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-type", "application/json")
		next.ServeHTTP(w, r)
	})
}

func MiddlewareRescue(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recovered := recover(); recovered != nil {
				fmt.Println("Unhandled handler panic:",recover())
				w.WriteHeader(http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}