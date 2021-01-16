using GLMakie.AbstractPlotting: backend_display, getscreen

function project_sp(scene, point)
    point_px = AbstractPlotting.project(scene, point)
    offset = Point2f0(minimum(pixelarea(scene)[]))
    return point_px .+ offset
end

@testset "unit tests" begin
    @testset "Window handling" begin
        AbstractPlotting.inline!(false)
        screen = GLMakie.global_gl_screen((100, 100), false)
        @test isopen(screen)
        fig, ax, splot = scatter(1:4);
        screen2 = display(fig)
        @test screen === screen2
        # TODO overload getscreen for figure
        @test getscreen(ax.scene) === screen
        close(screen)

        # assure we correctly close screen and remove it from plot
        @test getscreen(ax.scene) === nothing
        @test !events(ax.scene).window_open[]
        @test isempty(events(ax.scene).window_open.listeners)
    end

    @testset "Pick a plot element or plot elements inside a rectangle" begin
        N = 100000
        fig, ax, splot = scatter(1:N, 1:N)
        limits!(ax, 99990,100000, 99990,100000)
        screen = display(fig)
        yield()
        # test for pick a single data point (with idx > 65535)
        point_px = project_sp(ax.scene, Point2f0(N-1,N-1))
        plot,idx = pick(ax.scene, point_px)
        @test idx == N-1

        # test for pick a rectangle of data points (also with some indices > 65535)
        rect = FRect2D(99990.5,99990.5,8,8)
        origin_px = project_sp(ax.scene, Point(origin(rect)))
        tip_px = project_sp(ax.scene, Point(origin(rect) .+ widths(rect)))
        rect_px = IRect2D(round.(origin_px), round.(tip_px .- origin_px))
        #! there is no pick(::Scene,::IRect2D)
        plot_idx = pick(screen, rect_px)

        # objects returned in plot_idx should be either grid lines (i.e. LineSegments) or Scatter points
        @test all(pi-> pi[1] isa Union{LineSegments,Scatter, AbstractPlotting.Mesh}, plot_idx)
        # scatter points should have indices equal to those in 99991:99998
        scatter_plot_idx = filter(pi -> pi[1] isa Scatter, plot_idx)
        @test Set(last.(scatter_plot_idx)) == Set(99991:99998)
    end
end
