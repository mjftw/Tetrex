defmodule TetrexWeb.Components.BoardComponentsTest do
  use TetrexWeb.ConnCase
  import Phoenix.LiveViewTest

  alias TetrexWeb.Components.BoardComponents
  alias Tetrex.SparseGrid

  describe "tile rendering through board component" do
    test "renders all tile types including garbage without crashing" do
      # Test that all tile types render without function clause errors
      # This is the main test that would have caught the original bug
      tile_types = [:red, :green, :blue, :cyan, :yellow, :purple, :orange, :drop_preview, :garbage, nil]
      
      for tile_type <- tile_types do
        # Create a single-tile sparse grid
        grid_data = if tile_type == nil do
          [[nil]]
        else
          [[tile_type]]
        end
        
        sparsegrid = SparseGrid.new(grid_data)
        assigns = %{sparsegrid: sparsegrid}
        
        # This should not raise a FunctionClauseError
        html = render_component(&BoardComponents.board/1, assigns)
        
        # Verify the HTML contains expected content based on tile type
        case tile_type do
          :red -> assert html =~ "fill-red-400"
          :green -> assert html =~ "fill-green-400"  
          :blue -> assert html =~ "fill-blue-400"
          :cyan -> assert html =~ "fill-cyan-400"
          :yellow -> assert html =~ "fill-yellow-400"
          :purple -> assert html =~ "fill-purple-400"
          :orange -> assert html =~ "fill-orange-400"
          :drop_preview -> assert html =~ "fill-slate-500"
          :garbage -> assert html =~ "fill-gray-500"  # This is the key test for our fix
          nil -> assert html # Just verify it doesn't crash
        end
      end
    end

    test "specifically tests garbage tile rendering" do
      # This test specifically targets the bug we fixed
      garbage_row = [:garbage, :garbage, :garbage]
      grid_data = [garbage_row, garbage_row]
      
      sparsegrid = SparseGrid.new(grid_data)
      assigns = %{sparsegrid: sparsegrid}
      
      # Before our fix, this would raise:
      # ** (FunctionClauseError) no function clause matching in TetrexWeb.Components.BoardComponents."tile (overridable 1)"/1
      html = render_component(&BoardComponents.board/1, assigns)
      
      # Should contain garbage tiles rendered as gray
      assert html =~ "fill-gray-500"
      
      # Count the number of garbage tiles rendered
      garbage_count = html |> String.split("fill-gray-500") |> length() |> Kernel.-(1)
      assert garbage_count == 6  # 2 rows × 3 tiles = 6 garbage tiles
    end

    test "mixed board with garbage tiles" do
      # Test a realistic scenario with mixed tile types including garbage
      grid_data = [
        [:red, :green, :blue],
        [:garbage, :garbage, nil],
        [:orange, :garbage, :purple]
      ]
      
      sparsegrid = SparseGrid.new(grid_data)
      assigns = %{sparsegrid: sparsegrid}
      
      html = render_component(&BoardComponents.board/1, assigns)
      
      # Should contain all tile types without crashing
      assert html =~ "fill-red-400"
      assert html =~ "fill-green-400"
      assert html =~ "fill-blue-400"
      assert html =~ "fill-orange-400"
      assert html =~ "fill-purple-400"
      assert html =~ "fill-gray-500"  # garbage tiles
      
      # Count garbage tiles
      garbage_count = html |> String.split("fill-gray-500") |> length() |> Kernel.-(1)
      assert garbage_count == 3  # 3 garbage tiles in the grid
    end
  end

  describe "board/1 component" do
    test "renders board with various tile types including garbage" do
      # Create a sparse grid with different tile types including garbage
      grid_data = [
        [:red, :green, :blue],
        [:cyan, :yellow, :purple], 
        [:orange, :garbage, :drop_preview],
        [nil, :drop_preview, :garbage]
      ]
      
      sparsegrid = SparseGrid.new(grid_data)
      assigns = %{sparsegrid: sparsegrid}
      
      html = render_component(&BoardComponents.board/1, assigns)
      
      # Should contain all tile types
      assert html =~ "fill-red-400"
      assert html =~ "fill-green-400"
      assert html =~ "fill-blue-400"
      assert html =~ "fill-cyan-400"
      assert html =~ "fill-yellow-400"
      assert html =~ "fill-purple-400"
      assert html =~ "fill-orange-400"
      assert html =~ "fill-gray-500"  # garbage tiles

      assert html =~ "fill-slate-500" # drop_preview tiles
    end

    test "renders board with only garbage tiles" do
      # Create a board filled with garbage to test the specific bug scenario
      garbage_row = List.duplicate(:garbage, 10)
      grid_data = List.duplicate(garbage_row, 4)
      
      sparsegrid = SparseGrid.new(grid_data)
      assigns = %{sparsegrid: sparsegrid}
      
      # This should not raise a FunctionClauseError
      html = render_component(&BoardComponents.board/1, assigns)
      
      # Should contain multiple garbage tiles rendered as gray
      garbage_count = html |> String.split("fill-gray-500") |> length() |> Kernel.-(1)
      assert garbage_count > 0
    end
  end

  describe "playfield/1 component" do
    test "renders playfield with garbage tiles" do
      # Simulate a board state after receiving garbage
      grid_data = [
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [:garbage, :garbage, :garbage, nil, :garbage, :garbage, :garbage, :garbage, :garbage, :garbage]
      ]
      
      sparsegrid = SparseGrid.new(grid_data)
      board = %{playfield: sparsegrid}
      assigns = %{board: board, is_dead: false}
      
      html = render_component(&BoardComponents.playfield/1, assigns)
      
      # Should contain garbage tiles without crashing
      assert html =~ "fill-gray-500"
    end
  end


end
