function plot_nlp(ab,xy)
    a = ab(1);
    b = ab(2);
    xvec = linspace(-1.5,2,100);
    yvec = linspace(-1.5,2,100);
    
    
    [X,Y] = meshgrid(xvec,yvec);
    contour(X,Y,(1-X).^2 + a*(Y-X.^2).^2,100);

    hold on
    ts = linspace(0,2*pi,100);
    fill(b/2*cos(ts)-0.5,b/2*sin(ts),'r','FaceAlpha',0.2);
    
    fill([b*cos(ts-pi)-0.5 10*cos(pi-ts)-0.5],[b*sin(ts-pi) 10*sin(pi-ts)],'r','FaceAlpha',0.2);
    fill([-1.5 0 0 -1.5],[-1.5 -1.5 2 2],'r','FaceAlpha',0.2)
    xlabel('x');
    ylabel('y');
    plot(full(xy(1)),full(xy(2)),'*','MarkerSize',12,'LineWidth',2)
    axis square
    axis equal
    xlim([-1.5 2]);
    ylim([-1.5 2]);

end