#[macro_use]
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
#[get("/favicon.ico")]
fn favicon() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/favicon.ico")?)
}
#[get("/jolt")]
fn jolt() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/jolt/index.html")?)
}
#[get("/console.js")]
fn console_js() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/jolt/console.js")?)
}
#[get("/console.wasm")]
fn console_wasm() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/jolt/console.wasm")?)
}
#[get("/styles.css")]
fn styles_css() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/jolt/styles.css")?)
}
fn p404() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/404.html")?.set_status_code(StatusCode::NOT_FOUND))
}
fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    env::set_var("RUST_LOG", "actix_web=debug");
    env_logger::init();
    let sys = actix_rt::System::new("puff");

    HttpServer::new(|| {
        App::new()
            // cookie session middleware
            .wrap(CookieSession::signed(&[0; 32]).secure(false))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            // register favicon
            .service(favicon)
            .service(jolt)
            .service(console_js)
            .service(console_wasm)
            .service(styles_css)
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
