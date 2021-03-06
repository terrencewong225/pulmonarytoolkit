classdef PTKCinePanelWithTools < GemCinePanel
    % PTKCinePanelWithTools.  Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = protected)
        ViewerPanel
        
        % Used for programmatic pan, zoom, etc.
        LastCoordinates = [0, 0, 0]
        MouseIsDown = false
        ToolOnMouseDown
        LastCursor
        CurrentCursor = ''
    end
    
    methods
        function obj = PTKCinePanelWithTools(parent, viewer_panel, background_image_source, overlay_image_source, quiver_image_source, image_parameters, background_view_parameters, overlay_view_parameters)
            
            image_overlay_axes = PTKImageOverlayAxes(parent, background_image_source, overlay_image_source, quiver_image_source, image_parameters, background_view_parameters, overlay_view_parameters);
            obj = obj@GemCinePanel(parent, background_image_source, image_parameters, image_overlay_axes);
            obj.ViewerPanel = viewer_panel;
            obj.ImageSource = background_image_source;
        end

        function UpdateCursor(obj, hObject, mouse_is_down, keyboard_modifier)
            global_coords = obj.GetImageCoordinates;
            point_is_in_image = obj.ImageSource.Image.IsPointInImage(global_coords);
            if (~point_is_in_image)
                obj.MouseIsDown = false;
            end
            
            if point_is_in_image
                current_tool = obj.GetCurrentTool(mouse_is_down, keyboard_modifier);
                new_cursor = current_tool.Cursor;
            else
                new_cursor = 'arrow';
            end
            
            if ~strcmp(obj.CurrentCursor, new_cursor)
                set(hObject, 'Pointer', new_cursor);
                obj.CurrentCursor = new_cursor;
            end
            
        end
        
        function DrawImages(obj, update_background, update_overlay, update_quiver)
            if update_background
                obj.Axes.DrawBackgroundImage;
            end
            if update_overlay
                obj.Axes.DrawOverlayImage;
            end
            if update_quiver
                obj.Axes.DrawQuiverImage;
            end
        end
        
    end
    
    methods (Access = protected)
        
        function tool = GetCurrentTool(obj, mouse_is_down, keyboard_modifier)
            % Returns the tool whch is currently selected. If keyboard_modifier is
            % specified, then this may override the current tool
            
            tool = obj.ViewerPanel.GetCurrentTool(mouse_is_down, keyboard_modifier);
        end
        
        function input_has_been_processed = MouseDown(obj, click_point, selection_type, src)
            % This method is called when the mouse is clicked inside the control
            
            MouseDown@GemCinePanel(obj, click_point, selection_type, src);
            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;
            obj.MouseIsDown = true;
            tool = obj.GetCurrentTool(true, selection_type);
            global_coords = obj.GetImageCoordinates;
            if (obj.ImageSource.Image.IsPointInImage(global_coords))
                tool.MouseDown(screen_coords);
                obj.ToolOnMouseDown = tool;
                input_has_been_processed = true;
            else
                obj.ToolOnMouseDown = [];
                input_has_been_processed = false;
            end

            obj.UpdateCursor(src, true, selection_type);
            
        end

        function input_has_been_processed = MouseUp(obj, click_point, selection_type, src)
            % This method is called when the mouse is released inside the control
            
            MouseUp@GemCinePanel(obj, click_point, selection_type, src);
            input_has_been_processed = true;
            obj.MouseIsDown = false;

            screen_coords = obj.GetScreenCoordinates;
            obj.LastCoordinates = screen_coords;

            tool = obj.ToolOnMouseDown;
            if ~isempty(tool)
                global_coords = obj.GetImageCoordinates;
                if (obj.ImageSource.Image.IsPointInImage(global_coords))
                    tool.MouseUp(screen_coords);
                    obj.ToolOnMouseDown = [];
                end
            end
            obj.UpdateCursor(src, false, selection_type);
            
        end
        
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % Mouse has moved over the figure

            MouseHasMoved@GemCinePanel(obj, click_point, selection_type, src);
            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(false, selection_type);
            tool.MouseHasMoved(screen_coords, last_coords);
            
            obj.UpdateCursor(src, false, selection_type);
            input_has_been_processed = true;
        end
        
        function input_has_been_processed = MouseDragged(obj, click_point, selection_type, src)
            % Mouse dragged over the figure

            MouseDragged@GemCinePanel(obj, click_point, selection_type, src);
            screen_coords = obj.GetScreenCoordinates;
            last_coords = obj.LastCoordinates;
            
            tool = obj.GetCurrentTool(true, selection_type);
            tool.MouseDragged(screen_coords, last_coords);
            
            obj.UpdateCursor(src, true, selection_type);
            input_has_been_processed = true;
        end
 
        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event

            MouseExit@GemCinePanel(obj, click_point, selection_type, src);
            input_has_been_processed = false;
        end
    end
end