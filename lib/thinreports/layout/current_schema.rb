# frozen_string_literal: true

require 'json'
require 'rexml/document'

module Thinreports
  module Layout
    class CurrentSchema
      include Utils

      def initialize(current_schema)
        @current_schema = current_schema
        @legacy_svg = current_schema['svg'].dup
        @legacy_item_schemas = extract_legacy_item_schemas(legacy_svg)

        @legacy_svg = cleanup_svg(@legacy_svg)
      end

      def downgrade
        config = current_schema['config']
        page_config = config['page']

        {
          'version' => current_schema['version'],
          'title' => current_schema['config']['title'],
          'report' => {
            'paper-type' => page_config['paper-type'],
            'width' => page_config['width'].to_f,
            'height' => page_config['height'].to_f,
            'orientation' => page_config['orientation'],
            'margin' => page_config.values_at(
              'margin-top',
              'margin-right',
              'margin-bottom',
              'margin-left'
            ).map(&:to_f)
          },
          'items' => item_schemas
        }
      end

      attr_reader :current_schema, :legacy_svg, :legacy_item_schemas

      def item_schemas
        svg = REXML::Document.new(legacy_svg)
        build_item_schemas_from_svg(svg.elements['/svg/g'])
      end

      def build_item_schemas_from_svg(svg_elements)
        return [] unless svg_elements

        items = []

        svg_elements.each do |item_element|
          item_attributes = item_element.attributes

          items <<
            case item_element.attributes['class']
            when 's-text' then text_item_schema(item_attributes, extract_texts_from(item_element))
            when 's-image' then image_item_schema(item_attributes)
            when 's-rect' then rect_item_schema(item_attributes)
            when 's-ellipse' then ellipse_item_schema(item_attributes)
            when 's-line' then line_item_schema(item_attributes)
            when 's-tblock' then text_block_item_schema(item_attributes)
            when 's-iblock' then image_block_item_schema(item_attributes)
            when 's-pageno' then page_number_item_schema(item_attributes)
            when 's-list' then list_item_schema(item_element)
            else raise 'Unknown item type'
            end
        end

        items
      end

      def text_item_schema(attributes, texts)
        {
            'x-id' => attributes['id'],
            'x-left' => attributes['x'].to_s,
            'x-top' => attributes['y'].to_s,
            'x-width' => attributes['width'].to_s,
            'x-height' => attributes['height'].to_s,
            'x-display' => display(attributes['display']),
            # TODO texts
            'font-family' => attributes['style']['font-family'][0],
            'font-size' => attributes['style']['font-size'].to_i.to_s,
            'fill' => attributes['style']['color'],
            'text-anchor' => text_align(attributes['style']['text-align']),
            'x-valign' => vertical_align(attributes['style']['vertical-align']),
            'x-line-height' => line_height(attributes['style']['line-height']),
            'kerning' => letter_spacing(attributes['style']['letter-spacing'])

        }.merge font_style(attributes)
      end

      def rect_item_schema(attributes)
        {
            'x-id' => attributes['id'],
            'x' => attributes['x'].to_s,
            'y' => attributes['y'].to_s,
            'width' => attributes['width'].to_s,
            'height' => attributes['height'].to_s,
            'x-display' => display(attributes['display']),
            'stroke-width' => attributes['style']['border-width'].to_s,
            'stroke' => attributes['style']['border-color'],
            'x-stroke-type' => attributes['style']['border-style'],
            'fill' => attributes['style']['fill-color'],
            'rx' => attributes['border-radius'].to_s,
        }
      end

      def line_item_schema(attributes)
        {
            'x-id' => attributes['id'],
            'x1' => attributes['x1'].to_s,
            'y1' => attributes['y1'].to_s,
            'x2' => attributes['x2'].to_s,
            'y2' => attributes['y2'].to_s,
            'x-display' => display(attributes['display']),
            'stroke-width' => attributes['style']['border-width'].to_i.to_s,
            'stroke' => attributes['style']['border-color'],
            'x-stroke-type' => attributes['style']['border-style'],
        }
      end

      def ellipse_item_schema(attributes)
        {
          'id' => attributes['x-id'],
          'type' => 'ellipse',
          'cx' => attributes['cx'].to_f,
          'cy' => attributes['cy'].to_f,
          'rx' => attributes['rx'].to_f,
          'ry' => attributes['ry'].to_f,
          'display' => display(attributes['x-display']),
          'style' => {
            'border-width' => attributes['stroke-width'].to_f,
            'border-color' => attributes['stroke'],
            'border-style' => attributes['x-stroke-type'],
            'fill-color' => attributes['fill']
          }
        }
        {
            'x-id' => attributes['id'],
            'cx' => attributes['cx'].to_s,
            'cy' => attributes['cy'].to_s,
            'rx' => attributes['rx'].to_s,
            'ry' => attributes['ry'].to_s,
            'x-display' => display(attributes['display']),
            'stroke-width' => attributes['style']['border-width'].to_i.to_s,
            'stroke' => attributes['style']['border-color'],
            'x-stroke-type' => attributes['style']['border-style'],
            'fill' => attributes['style']['fill-color'],
        }
      end

      def image_item_schema(attributes)
        # _, image_type, image_data = attributes['xlink:href'].match(%r{^data:(image/[a-z]+?);base64,(.+)}).to_a

        # {
        #   'id' => attributes['x-id'],
        #   'type' => 'image',
        #   'x' => attributes['x'].to_f,
        #   'y' => attributes['y'].to_f,
        #   'width' => attributes['width'].to_f,
        #   'height' => attributes['height'].to_f,
        #   'display' => display(attributes['x-display']),
        #   'data' => {
        #     'mime-type' => image_type,
        #     'base64' => image_data
        #   }
        # }
        {
          'x-id' => attributes['id'],
          'x' => attributes['x'].to_s,
          'y' => attributes['y'].to_s,
          'width' => attributes['width'].to_s,
          'height' => attributes['height'].to_s,
          'x-display' => display(attributes['display']),
          'xlink:href' => sprintf('data:%s;base64,%s', attributes['data']['mime-type'], attributes['data']['base64']),
        }
      end

      def page_number_item_schema(attributes)
        {
            'x-id' => attributes['id'],
            'x-left' => attributes['x'].to_s,
            'x-top' => attributes['y'].to_s,
            'x-width' => attributes['width'].to_s,
            'x-height' => attributes['height'].to_s,
            'x-format' => attributes['format'],
            'x-target' => attributes['target'],
            'x-display' => display(attributes['display']),
            'font-family' => attributes['style']['font-family'][0],
            'font-size' => attributes['style']['font-size'].to_s,
            'fill' => attributes['style']['color'],
            #'font-style' => ,
            'text-anchor' => text_align(attributes['style']['text-align']),
            'x-overflow' => attributes['style']['overflow'],
      }.merge font_style(attributes)

      end

      def image_block_item_schema(attributes)
        {
            'x-id' => attributes['id'],
            'x-left' => attributes['x'].to_s,
            'x-top' => attributes['y'].to_s,
            'x-width' => attributes['width'].to_s,
            'x-height' => attributes['height'].to_s,
            'x-display' => display(attributes['display']),
            'x-position-x' => attributes['style']['position-x'],
            'x-position-y' => image_position_y(attributes['style']['position-y']),
        }
      end

      def text_block_item_schema(attributes)
        additionals = {}
        additionals['x-format-base'] = attributes['format']['base']
        additionals['x-format-type'] = attributes['format']['type']

        case additionals['x-format-type']
        when 'datetime'
          additionals['x-format-datetime-format'] = attributes['format']['datetime']['format']
        when 'number'
          additionals['x-format-number-delimiter'] = attributes['format']['number']['delimiter']
          additionals['x-format-number-precision'] = attributes['format']['number']['precision']
        when 'padding'
          additionals['x-format-padding-length'] = attributes['format']['padding']['length'].to_s
          additionals['x-format-padding-char'] = attributes['format']['padding']['char']
          additionals['x-format-padding-direction'] = attributes['format']['padding']['direction']
        end

        {
          'x-id' => attributes['id'],
          'x-left' => attributes['x'].to_s,
          'x-top' => attributes['y'].to_s,
          'x-width' => attributes['width'].to_s,
          'x-height' => attributes['height'].to_s,
          'x-display' => display(attributes['display']),
          'x-value' => attributes['value'],
          'x-multiple' => attributes['multiple-line'].to_s,
          'x-ref-id' => attributes['reference-id'],
          'font-family' => attributes['style']['font-family'][0],
          'font-size' => attributes['style']['font-size'].to_i.to_s,
          'fill' => attributes['style']['color'],
          'text-anchor' => text_align(attributes['style']['text-align']),
          'x-valign' => vertical_align(attributes['style']['vertical-align']),
          'x-line-height' => line_height(attributes['style']['line-height']),
          'kerning' => letter_spacing(attributes['style']['letter-spacing']),
          'x-overflow' => attributes['style']['overflow'],
          'x-word-wrap' => attributes['style']['word-wrap'],

        }.merge additionals, font_style(attributes)
      end

      def list_item_schema(legacy_element)
        current_schema = legacy_item_schemas[legacy_element.attributes['x-id']]

        header = list_section_schema('header', legacy_element, current_schema)
        detail = list_section_schema('detail', legacy_element, current_schema)
        page_footer = list_section_schema('page-footer', legacy_element, current_schema)
        footer = list_section_schema('footer', legacy_element, current_schema)

        schema = {
          'id' => current_schema['id'],
          'type' => Core::Shape::List::TYPE_NAME,
          'content-height' => current_schema['content-height'].to_f,
          'auto-page-break' => current_schema['page-break'] == 'true',
          'display' => display(current_schema['display']),
          'header' => header,
          'detail' => detail,
          'page-footer' => page_footer,
          'footer' => footer
        }

        page_footer['translate']['y'] += detail['height'] if page_footer['enabled']

        if footer['enabled']
          footer['translate']['y'] += detail['height']
          footer['translate']['y'] += page_footer['height'] if page_footer['enabled']
        end
        schema
      end

      def list_section_schema(section_name, legacy_list_element, legacy_list_schema)
        legacy_section_schema = legacy_list_schema[section_name]
        return {} if legacy_section_schema.empty?

        section_item_elements = legacy_list_element.elements["g[@class='s-list-#{section_name}']"]

        section_schema = {
          'height' => legacy_section_schema['height'].to_f,
          'translate' => {
            'x' => legacy_section_schema['translate']['x'].to_f,
            'y' => legacy_section_schema['translate']['y'].to_f
          },
          'items' => build_item_schemas_from_svg(section_item_elements)
        }

        unless section_name == 'detail'
          section_schema['enabled'] = legacy_list_schema["#{section_name}-enabled"] == 'true'
        end
        section_schema
      end

      def extract_texts_from(text_item_element)
        [].tap do |texts|
          text_item_element.each_element('text') { |e| texts << e.text }
        end
      end

      def image_position_y(legacy_position_y)
        case legacy_position_y
        when 'top' then 'top'
        when 'center' then 'middle'
        when 'bottom' then 'bottom'
        end
      end

      def display(legacy_display)
        legacy_display ? 'true' : 'false'
      end

      def font_style(attributes)
        return {} if attributes['style'] == nil
        styles = attributes['style']['font-style']
        return {} if styles == nil

        legacy_styles = {}

        legacy_styles['font-weight'] = styles.include?('bold') ? 'bold' : 'normal'
        legacy_styles['font-style'] = styles.include?('italic') ? 'italic' : 'normal'

        decorations = []
        decorations << 'underline' if styles.include?('underline')
        decorations << 'line-through' if styles.include?('linethrough')
        legacy_styles['text-decoration'] = decorations.join(' ')
        legacy_styles
      end

      def text_align(legacy_text_align)
        case legacy_text_align
        when 'left' then 'start'
        when 'center' then 'middle'
        when 'right' then 'end'
        else 'start'
        end
      end

      def vertical_align(legacy_vertical_align)
        return '' unless legacy_vertical_align

        case legacy_vertical_align
        when 'top' then 'top'
        when 'middle' then 'center'
        when 'bottom' then 'bottom'
        else 'top'
        end
      end

      def line_height(legacy_line_height)
        blank_value?(legacy_line_height) ? '' : legacy_line_height.to_s
      end

      def letter_spacing(legacy_letter_spacing)
        case legacy_letter_spacing
        when '' then 'auto'
        else legacy_letter_spacing.to_s
        end
      end

      def extract_legacy_item_schemas(svg)
        items = {}
        svg.scan(/<!--SHAPE(.*?)SHAPE-->/) do |(item_schema_json)|
          item_schema = JSON.parse(item_schema_json)
          items[item_schema['id']] = item_schema
        end
        items
      end

      def cleanup_svg(svg)
        cleaned_svg = svg.gsub(/<!--SHAPE.*?SHAPE-->/, '')
        cleaned_svg.gsub(/<!--LAYOUT(.*?)LAYOUT-->/) { $1 }
      end
    end
  end
end