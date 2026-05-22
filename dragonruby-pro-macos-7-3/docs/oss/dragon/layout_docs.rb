# coding: utf-8
# Copyright 2019 DragonRuby LLC
# MIT License
# outputs_docs.rb has been released under MIT (*only this file*).

module LayoutDocs
  def docs_method_sort_order
    [
      :docs_class,
      :docs_rect,
      :docs_debug_primitives
    ]
  end

  def docs_class
    DocsOrganizer.get_docsify_content path: "docs/api/layout.md",
                                      heading_level: 1,
                                      heading_include: "Layout",
                                      max_depth: 0
  end

  def docs_rect
    DocsOrganizer.get_docsify_content path: "docs/api/layout.md",
                                      heading_level: 2,
                                      heading_include: __method__.to_s.gsub("docs_", "")
  end

  def docs_debug_primitives
    DocsOrganizer.get_docsify_content path: "docs/api/layout.md",
                                      heading_level: 2,
                                      heading_include: __method__.to_s.gsub("docs_", "")
  end
end

class GTK::Layout
  extend Docs
  extend LayoutDocs
end
