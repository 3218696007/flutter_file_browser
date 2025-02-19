class PathNode {
  final String path;
  PathNode? parent;
  PathNode? child;

  PathNode(this.path);

  void setChild(PathNode node) {
    child = node;
    node.parent = this;
  }

  void clearChild() {
    if (child != null) {
      child!.parent = null;
      child = null;
    }
  }
}