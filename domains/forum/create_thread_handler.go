package forum

import (
	"encoding/json"
	"github.com/gorilla/mux"
	"io/ioutil"
	"net/http"
	"strings"
	"time"
)

func CreateThreadHandler(w http.ResponseWriter, r *http.Request) {
	bodyContent, err := ioutil.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	args := struct {
		Title   string    `json:"title"`
		Author  string    `json:"author"`
		Message string    `json:"message"`
		Slug    string    `json:"slug"`
		Created time.Time `json:"created"`
	}{}

	err = json.Unmarshal(bodyContent, &args)
	if err != nil {
		if strings.HasPrefix(err.Error(), `parsing time "{}"`) {
			args.Created = time.Time{}
		} else {
			w.WriteHeader(http.StatusInternalServerError)//Возможно, лучше BadRequest
			return
		}
	}

	code, response := createThread(mux.Vars(r)["slug"], args.Title, args.Author, args.Message, args.Slug, args.Created)
	responseJSON, err := json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(code)
	_, err = w.Write(responseJSON)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	return
}
