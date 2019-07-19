extern crate actix_web;

use std::{env, io};

use actix_files as fs;
use actix_session::{CookieSession};
use actix_web::http::{header, StatusCode};
use actix_web::{
    guard, middleware, web, App,
    HttpResponse, HttpRequest, HttpServer,
    Result,
};
fn p404() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/404.html")?.set_status_code(StatusCode::NOT_FOUND))
}
fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    env::set_var("RUST_LOG", "actix_web=debug");
    env_logger::init();
    let sys = actix_rt::System::new("puff");
    let run_dir = args[2].clone();

    HttpServer::new(move || {
        App::new()
            // cookie session middleware
            .wrap(CookieSession::signed(&[0; 32]).secure(false))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            .service(fs::Files::new("favicon.ico", &run_dir).index_file("favicon.ico"))
            .service(fs::Files::new("jolt", format!("{}/jolt", &run_dir)).index_file("index.html"))
            .service(fs::Files::new("console.js", format!("{}/jolt", &run_dir)).index_file("console.js"))
            .service(fs::Files::new("console.wasm", format!("{}/jolt", &run_dir)).index_file("console.wasm"))
            .service(fs::Files::new("styles.css", format!("{}/jolt", &run_dir)).index_file("styles.css"))
            .service(web::resource("/").route(web::get().to(|req: HttpRequest| {
                println!("{:?}", req);
                HttpResponse::Found()
                    .header(header::LOCATION, "jolt")
                    .finish()
            })))
            .default_service(
                // 404 for GET request
                web::resource("")
                    .route(web::get().to(p404))
                    // all requests that are not `GET`
                    .route(
                        web::route()
                            .guard(guard::Not(guard::Get()))
                            .to(|| HttpResponse::MethodNotAllowed()),
                    ),
            )
    })
    .bind(args[1].clone())?
    .start();

    println!("{}",format!("Starting http server: {}", args[1]));
    sys.run()
}
