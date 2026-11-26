//> using scala 3.3
// Scala 3 playground for Lesson 12, step 7 (Metals via coc).
// Needs `setup.sh --with-scala` (Coursier, Metals, scala-cli, a JDK 17+).
// First time in this folder:  :!scala-cli setup-ide .   then  :CocRestart
// Run it:                      :!scala-cli run .
//
// The TODO markers below also feed Lesson 6's quickfix demo.

enum Shape:
  case Circle(radius: Double)
  case Rect(width: Double, height: Double)

// TODO: K on `area` -- hover shows the signature Metals inferred
extension (s: Shape)
  def area: Double = s match
    case Shape.Circle(r)  => math.Pi * r * r
    case Shape.Rect(w, h) => w * h

// TODO: gd on `Shape` above, Ctrl-O back; gr on `describe` for its uses
def describe(s: Shape): String =
  f"$s%-24s area ${s.area}%8.2f"

@main def run(): Unit =
  val shapes = List(Shape.Circle(1.0), Shape.Rect(2.0, 3.5))
  shapes.map(describe).foreach(println)
  // TODO: type `shapes.` on a new line here and watch the completion menu
