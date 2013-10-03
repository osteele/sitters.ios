class SittersScreen < PM::TableScreen
  searchable placeholder: "Search sitters"

  title "Sitters"

  def table_data
    [{
      title: "",
      cells: Sitter.all.map { |sitter| { title: sitter.name, action: :tapped_sitter } }
    }]
  end

  def tapped_sitter(args={})
    PM.logger.debug args
  end
end
