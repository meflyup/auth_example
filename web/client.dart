import "dart:html"; 
import "dart:convert";

//login form
InputElement loginUsername = querySelector("#login_username");
InputElement loginPassword = querySelector("#login_password");
ButtonElement sendLoginBtn = querySelector("#send_login");

//new user form
InputElement newUsername = querySelector("#new_username");
InputElement newPassword = querySelector("#new_password");
CheckboxInputElement isAdmin = querySelector("#new_user_admin");
ButtonElement sendNewUserBtn = querySelector("#send_new_user");

//echo service
InputElement echoInput = querySelector("#echo_input");
ButtonElement sendEchoBtn = querySelector("#send_echo");

//users service
ButtonElement listUsersBtn = querySelector("#list_users");
PreElement viewUsers = querySelector("#users_view");

//logout button
ButtonElement sendLogoutBtn = querySelector("#logout");

void main() { 
  
  sendLoginBtn.onClick.listen((_) {
    sendLogin(loginUsername.value, loginPassword.value);
  });
  
  sendNewUserBtn.onClick.listen((_) {
    sendNewUser(newUsername.value, newPassword.value, isAdmin.checked);
  });
  
  sendEchoBtn.onClick.listen((_) {
    sendEcho(echoInput.value);
  });
  
  listUsersBtn.onClick.listen((_) {
    listUsers();
  });
  
  sendLogoutBtn.onClick.listen((_) {
    sendLogout();
  });
  
}

clearForms() {
  loginUsername.value = "";
  loginPassword.value = "";
  
  newUsername.value = "";
  newPassword.value = "";
  isAdmin.checked = false;
  
  echoInput.value = "";
}

sendLogin(String username, String password) {
  if (username.trim().isEmpty || password.trim().isEmpty) {
    return;
  }
  
  var user = {"username": username, "password": password};
  
  HttpRequest.request("/services/login", method: "POST", 
      requestHeaders: {"content-type": "application/json"}, 
      sendData: JSON.encode(user)).then((request) {
    
    window.alert(request.response);
    clearForms();
    
  }, onError: (ProgressEvent e) {
    HttpRequest req = e.target;
    window.alert("status: ${req.status} response: ${req.responseText}");
  });
}

sendNewUser(String username, String password, bool admin) {
  if (username.trim().isEmpty || password.trim().isEmpty) {
    return;
  }
  
  var user = {"username": username, "password": password, "admin": admin};
  
  HttpRequest.request("/services/newuser", method: "POST", 
      requestHeaders: {"content-type": "application/json"}, 
      sendData: JSON.encode(user)).then((request) {
    
    window.alert(request.response);
    clearForms();
    
  }, onError: (ProgressEvent e) {
    HttpRequest req = e.target;
    window.alert("status: ${req.status} response: ${req.responseText}");
  });
}

sendEcho(String input) {
  if (input.trim().isEmpty || input.trim().isEmpty) {
    return;
  }
  
  HttpRequest.getString("/services/private/echo/$input").then((result) {
    window.alert("response: $result");
  }, onError: (ProgressEvent e) {
    HttpRequest req = e.target;
    window.alert("status: ${req.status} response: ${req.responseText}");
  });
}

listUsers() {
  HttpRequest.request("/services/private/listusers").then((req) {
    var str = new StringBuffer();
    
    JSON.decode(req.response).forEach((user) {
      str.write("username: ${user["username"]} admin: ${user["admin"]}\n");
    });
    
    viewUsers.text = str.toString();
    
  }, onError: (ProgressEvent e) {
    HttpRequest req = e.target;
    window.alert("status: ${req.status} response: ${req.responseText}");
  });
}

sendLogout() {
  HttpRequest.getString("/services/logout")
      .then((result) => window.alert(result), onError: (ProgressEvent e) {
          HttpRequest req = e.target;
          window.alert("status: ${req.status} response: ${req.responseText}");
      });
}
