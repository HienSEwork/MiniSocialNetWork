// DEPRECATED: friends.js removed — server-side FriendsController and ApiClient
// are used instead. This file is kept as a harmless stub to avoid 404s if
// referenced accidentally. Remove it from the repository with:
//
//   git rm --cached wwwroot/js/friends.js   # remove tracked file
//   git commit -m "Remove deprecated client-side friends.js"
//
// If a script tag still accidentally includes this file it will no-op.

(function () {
  // noop to avoid runtime errors if included by older views
  window.Friends = window.Friends || {
    loadFriends: () => { /* noop - now handled server-side */ },
    searchUsers: () => { /* noop - now handled server-side */ },
    sendRequest: () => { /* noop - now handled server-side */ },
    loadRequests: () => { /* noop - now handled server-side */ },
    respondRequest: () => { /* noop - now handled server-side */ },
    acceptFromSearch: (id) => { location.href = '/Friends/Requests'; }
  };
})();