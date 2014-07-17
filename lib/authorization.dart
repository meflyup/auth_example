library authorization;

import 'package:redstone/server.dart' as app;

const String ADMIN = "ADMIN";

class Secure {
  
  final String role;
  
  const Secure(this.role);
  
}


void AuthorizationPlugin(app.Manager manager) {
  
  manager.addRouteWrapper(Secure, (metadata, pathSegments, injector, request, route) {
    
    String role = (metadata as Secure).role;
    Set userRoles = app.request.session["roles"];
    if (!userRoles.contains(role)) {
      throw new app.ErrorResponse(403, {"error": "NOT_AUTHORIZED"});
    }
    
    return route(pathSegments, injector, request);
    
  }, includeGroups: true);
  
}