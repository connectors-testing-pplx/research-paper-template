# analysis/05-network.R
# Build a network from an edge list, compute centrality and communities,
# and render the network figure plus a node-metrics table.

source("analysis/00-config.R")
source("R/network-analysis.R")

edge_path <- file.path(raw_dir, network_vars$edge_file)
stopifnot(file.exists(edge_path))

edges <- data.table::fread(edge_path)
net <- make_graph(edges, directed = network_vars$directed)

# Optionally color nodes by LCA class if class assignments exist.
node_attrs <- NULL
class_path <- file.path(processed_dir, "lca-classes.rds")
if (file.exists(class_path)) {
  classes <- readRDS(class_path)
  if ("class" %in% names(classes) && "id" %in% names(classes)) {
    node_attrs <- data.frame(id = classes$id, class = classes$class)
  }
}
net <- make_graph(edges, directed = network_vars$directed, node_attrs = node_attrs)

metrics <- network_metrics(net)
write.csv(metrics, file.path(tables_dir, "network-summary.csv"), row.names = FALSE)
print(metrics)

net <- add_centrality(net, measures = c("degree", "betweenness", "eigen"))
net <- detect_communities(net, algorithm = "louvain")

node_table <- as_tibble_vertex(net)
write.csv(node_table, file.path(tables_dir, "network-node-metrics.csv"), row.names = FALSE)

plot_network(net, by = "community", size_by = "degree",
             out_path = file.path(figures_dir, "network.png"))

saveRDS(net, file.path(processed_dir, "network.rds"))
message("Network analysis done; ", igraph::vcount(net), " nodes, ",
        igraph::ecount(net), " edges")
