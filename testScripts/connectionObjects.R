{# PostgreSQL ----
  
  # Postgres connection object
  pgHost <- 'analytic-environment-postgresql.analytics.svc.cluster.local'
  pgPort <- 5432
  pgUser <- 'postgres'
  pgPass <- 'mypass'
  
  library(RPostgreSQL)
  
  #Create connection object
  pgConn <- DBI::dbConnect(drv = RPostgreSQL::PostgreSQL(),
                           host = pgHost,
                           port = pgPort,
                           user = pgUser,
                           password = pgPass)
  
  # Return the databases within the connected instance
  DBI::dbGetQuery(conn = pgConn,
                  statement = "SELECT * FROM pg_database")
  
}# close postgres section

{# MongoDB ----
  library(mongolite)
  
  mongoURI <- 'mongodb://root:mypass@analytic-environment-mongodb.analytics.svc.cluster.local:27017'
  mongoURImodler <- 'mongodb://modelr:C8dsdfwS=C^@analytic-environment-mongodb.analytics.svc.cluster.local:27017/'
  mongoDB <- 'admin'
  mongoCollection <- ''
  
  mongoConn <- mongolite::mongo(url = mongoURI,
                                db = mongoDB)
  
  mongoConn$find('{}')
  
  {# Info about existing users ----
    
    userInfo <- mongoConn$run('{"usersInfo":1,"showCredentials":true}')
    
    glimpse(userInfo$users)
    
  }# close Info about existing users section
  
  {# Info about existing roles ----
    
    rolesInfo <- mongoConn$run('{"rolesInfo":1,"showBuiltinRoles":true}')
    
    rolesInfo
    
    glimpse(rolesInfo$ok)
    
  }# close Info about existing roles section
  
  {# Info about existing databases ----
    
    mongoConn$run('{"listDatabases":1}')
    
  }# close Info about existing databases section
  
  {# Create a new database ----
    
    mongoConn$run(command = '{"listDatabases":1}')
    
    mongoConnNewDB <- mongolite::mongo(url = mongoURI,
                                  db = 'model_results')
    
    mongoConnNewDB$find('{}')
    
  }# close Create a new database section
  
  {# Create a new user ----
    
    createUser <- '{"createUser":"modelr","pwd": "C8dsdfwS=C^","roles":[{"role":"readWriteAnyDatabase","db":"admin"}]}'
    
    mongoConn$run(createUser)
    
  }# close Create a new user section
  
  {# Connect with new user ----
    
    mongoConnModler <- mongolite::mongo(url = mongoURImodler,
                                  db = 'ModelResults',
                                  collection = 'user')
    
    mongoConnModler$find('{}')
    
    mongoConnModler$run('{"listCollections":1}')
    
    mongoConnModler$drop()
    mongoConnModler$insert('{"users":"modelr"}')  
    
  }# close Connect with new users section
  
}# close MongoDB section