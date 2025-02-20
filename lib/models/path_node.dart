class PathNode {
  final String path;
  PathNode? parent;
  PathNode? child;

  PathNode(this.path);

  void setChild(PathNode newChild) {
    child?.parent = null;
    newChild.parent = this;
    child = newChild;
  }
}
