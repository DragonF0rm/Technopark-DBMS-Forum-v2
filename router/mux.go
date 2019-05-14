package router

import (
	forumDomain  "github.com/DragonF0rm/Technopark-DBMS-Forum/domains/forum"
	postDomain   "github.com/DragonF0rm/Technopark-DBMS-Forum/domains/post"
	statusDomain "github.com/DragonF0rm/Technopark-DBMS-Forum/domains/service"
	threadDomain "github.com/DragonF0rm/Technopark-DBMS-Forum/domains/thread"
	userDomain   "github.com/DragonF0rm/Technopark-DBMS-Forum/domains/user"
	"github.com/gorilla/mux"
	"net/http"
)

func GetRouter()(router *mux.Router){
	router = mux.NewRouter()
	api := router.PathPrefix("/api").Subrouter()
	forum := api.PathPrefix("/forum").Subrouter()
	forum.Handle("/create", MiddlewareLog(forumDomain.CreateHandler, ForumCreate)).Methods(http.MethodPost)
	forum.Handle("/{slug}/details", MiddlewareLog(forumDomain.DetailsHandler, ForumDetails)).Methods(http.MethodGet)
	forum.Handle("/{slug}/create", MiddlewareLog(forumDomain.CreateThreadHandler, ForumCreateThread)).Methods(http.MethodPost)
	forum.Handle("/{slug}/users", MiddlewareLog(forumDomain.UsersHandler, ForumUsers)).Methods(http.MethodGet)
	forum.Handle("/{slug}/threads", MiddlewareLog(forumDomain.ThreadsHandler, ForumThreads)).Methods(http.MethodGet)

	post := api.PathPrefix("/post").Subrouter()
	post.Handle("/{id}/details", MiddlewareLog(postDomain.DetailsHandler, PostDetails)).Methods(http.MethodGet)
	post.Handle("/{id}/details", MiddlewareLog(postDomain.EditHandler, PostEdit)).Methods(http.MethodPost)

	service := api.PathPrefix("/service").Subrouter()
	service.Handle("/clear", MiddlewareLog(statusDomain.ClearHandler, ServiceClear)).Methods(http.MethodPost)
	service.Handle("/status", MiddlewareLog(statusDomain.StatusHandler, ServiceStatus)).Methods(http.MethodGet)

	thread  := api.PathPrefix("/thread").Subrouter()
	thread.Handle("/{slug_or_id}/create", MiddlewareLog(threadDomain.CreatePostsHandler, ThreadCreatePost)).Methods(http.MethodPost)
	thread.Handle("/{slug_or_id}/details", MiddlewareLog(threadDomain.DetailsHandler, ThreadDetails)).Methods(http.MethodGet)
	thread.Handle("/{slug_or_id}/details", MiddlewareLog(threadDomain.UpdateHandler, ThreadUpdate)).Methods(http.MethodPost)
	thread.Handle("/{slug_or_id}/posts", MiddlewareLog(threadDomain.PostsHandler, ThreadPosts)).Methods(http.MethodGet)
	thread.Handle("/{slug_or_id}/vote", MiddlewareLog(threadDomain.VoteHandler, ThreadVote)).Methods(http.MethodPost)

	user := api.PathPrefix("/user").Subrouter()
	user.Handle("/{nickname}/create", MiddlewareLog(userDomain.CreateHandler, UserCreate)).Methods(http.MethodPost)
	user.Handle("/{nickname}/profile", MiddlewareLog(userDomain.ProfileHandler, UserProfile)).Methods(http.MethodGet)
	user.Handle("/{nickname}/profile", MiddlewareLog(userDomain.EditProfileHandler, UserEditProfile)).Methods(http.MethodPost)

	router.Use(MiddlewareBasicHeaders)
	go StartTransmitStats()
	//router.Use(MiddlewareRescue)//ДОЛЖНА БЫТЬ ПОСЛЕДНЕЙ
	return
}


