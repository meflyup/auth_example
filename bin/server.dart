import 'package:redstone/server.dart' as app;
import 'package:di/di.dart';
import 'package:shelf_static/shelf_static.dart';

import '../lib/database.dart';
import '../lib/authentication.dart';
import '../lib/authorization.dart';
import '../lib/services.dart';

main() {

  app.setupConsoleLog();
  app.setShelfHandler(createStaticHandler("web", 
                                          defaultDocument: "index.html", 
                                          serveFilesOutsidePath: true));

  var dbUri = "mongodb://localhost/auth_example";
  var poolSize = 3;

  app.addModule(new Module()
      ..bind(MongoDbPool, toValue: new MongoDbPool(dbUri, poolSize)));
  
  app.addPlugin(AuthorizationPlugin);

  app.start();

}