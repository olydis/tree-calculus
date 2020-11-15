use trees::*;
use std::rc::Rc;
use syn::parse::{Parse, ParseStream, Result};
use syn::{parse_str, parenthesized, bracketed, braced};

use crate::Program::{Leaf, Stem, Fork};
use crate::Tree::{Value};

#[macro_use]
extern crate nom;

named!(get_leaf<&str,&str>,
    tag!("~")
);

fn main() {
    let res = get_leaf("~");
    println!("{:?}",res);

// Done(" there", "hi")


/*
#[macro_use]
extern crate nom;
use nom::IResult;
use std::str::from_utf8;
use std::fmt::Debug;


named!(get_leaf<&str,&str>,
    tag_s!("~")
);

fn main() {

    let res = get_leaf ("~");
      println!("{:?}",res);


    fn node() -> Tree {  Value (Rc::new(Leaf)) }
        
    fn app (t1:Tree,t2:Tree) -> Tree { Tree::app(t1,t2)  }

    let t1 : std::result::Result<Tree, syn::Error> = syn::parse_str("(~)") ;
    
	match syn::parse_str("~") {
	    Ok (t) => t,
	    _ => panic! {"couldn't parse"}
	};

    println!("The value of t1 is: {:?}",t1);


    let t2 = app(node(),node());
    println!("The value of t2 is: {}", t2);

    let t3 = app(app(node(),t1),t2);
    println!("The value of t3 is: {}", t3);

    pub fn leaf() -> Program { Leaf }
    
    let v1 = leaf(); 
    println!("The leaf is: {}", v1); 

    pub fn k() -> Program { Stem(Rc::new(Leaf)) } 
    println!("k is: {}", k()); 

    let v3 = Fork(Rc::new(Leaf), Rc::new(Stem(Rc::new(Leaf))));
    println!("The fork is: {}", v3);

    let v4a = leaf(); 
    let v4 = Tree::eval (v3,v4a); 
    println!("v4 is: {}", v4);

    pub fn id() -> Program { Fork(Rc::new(k()), Rc::new(k())) }
    println!("id is: {}", id());

    let v5 = Tree::eval(id(), leaf());
       println!("id leaf is: {}", v5);

 */
  
}
