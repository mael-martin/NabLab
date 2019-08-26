/**
 * generated by Xtext 2.15.0
 */
package fr.cea.nabla.nablagen.provider;

import fr.cea.nabla.nablagen.util.NablagenAdapterFactory;

import java.util.ArrayList;
import java.util.Collection;

import org.eclipse.emf.common.notify.Adapter;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.Notifier;

import org.eclipse.emf.edit.provider.ChangeNotifier;
import org.eclipse.emf.edit.provider.ComposeableAdapterFactory;
import org.eclipse.emf.edit.provider.ComposedAdapterFactory;
import org.eclipse.emf.edit.provider.IChangeNotifier;
import org.eclipse.emf.edit.provider.IDisposable;
import org.eclipse.emf.edit.provider.IEditingDomainItemProvider;
import org.eclipse.emf.edit.provider.IItemLabelProvider;
import org.eclipse.emf.edit.provider.IItemPropertySource;
import org.eclipse.emf.edit.provider.INotifyChangedListener;
import org.eclipse.emf.edit.provider.IStructuredItemContentProvider;
import org.eclipse.emf.edit.provider.ITreeItemContentProvider;

/**
 * This is the factory that is used to provide the interfaces needed to support Viewers.
 * The adapters generated by this factory convert EMF adapter notifications into calls to {@link #fireNotifyChanged fireNotifyChanged}.
 * The adapters also support Eclipse property sheets.
 * Note that most of the adapters are shared among multiple instances.
 * <!-- begin-user-doc -->
 * <!-- end-user-doc -->
 * @generated
 */
public class NablagenItemProviderAdapterFactory extends NablagenAdapterFactory implements ComposeableAdapterFactory, IChangeNotifier, IDisposable {
	/**
	 * This keeps track of the root adapter factory that delegates to this adapter factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ComposedAdapterFactory parentAdapterFactory;

	/**
	 * This is used to implement {@link org.eclipse.emf.edit.provider.IChangeNotifier}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected IChangeNotifier changeNotifier = new ChangeNotifier();

	/**
	 * This keeps track of all the supported types checked by {@link #isFactoryForType isFactoryForType}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Collection<Object> supportedTypes = new ArrayList<Object>();

	/**
	 * This constructs an instance.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public NablagenItemProviderAdapterFactory() {
		supportedTypes.add(IEditingDomainItemProvider.class);
		supportedTypes.add(IStructuredItemContentProvider.class);
		supportedTypes.add(ITreeItemContentProvider.class);
		supportedTypes.add(IItemLabelProvider.class);
		supportedTypes.add(IItemPropertySource.class);
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.NablagenModule} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected NablagenModuleItemProvider nablagenModuleItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.NablagenModule}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createNablagenModuleAdapter() {
		if (nablagenModuleItemProvider == null) {
			nablagenModuleItemProvider = new NablagenModuleItemProvider(this);
		}

		return nablagenModuleItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.Workflow} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected WorkflowItemProvider workflowItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.Workflow}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createWorkflowAdapter() {
		if (workflowItemProvider == null) {
			workflowItemProvider = new WorkflowItemProvider(this);
		}

		return workflowItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.WorkflowComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected WorkflowComponentItemProvider workflowComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.WorkflowComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createWorkflowComponentAdapter() {
		if (workflowComponentItemProvider == null) {
			workflowComponentItemProvider = new WorkflowComponentItemProvider(this);
		}

		return workflowComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.ChildComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ChildComponentItemProvider childComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.ChildComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createChildComponentAdapter() {
		if (childComponentItemProvider == null) {
			childComponentItemProvider = new ChildComponentItemProvider(this);
		}

		return childComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.Ir2IrComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Ir2IrComponentItemProvider ir2IrComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.Ir2IrComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createIr2IrComponentAdapter() {
		if (ir2IrComponentItemProvider == null) {
			ir2IrComponentItemProvider = new Ir2IrComponentItemProvider(this);
		}

		return ir2IrComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.Nabla2IrComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Nabla2IrComponentItemProvider nabla2IrComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.Nabla2IrComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createNabla2IrComponentAdapter() {
		if (nabla2IrComponentItemProvider == null) {
			nabla2IrComponentItemProvider = new Nabla2IrComponentItemProvider(this);
		}

		return nabla2IrComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.TagPersistentVariablesComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected TagPersistentVariablesComponentItemProvider tagPersistentVariablesComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.TagPersistentVariablesComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createTagPersistentVariablesComponentAdapter() {
		if (tagPersistentVariablesComponentItemProvider == null) {
			tagPersistentVariablesComponentItemProvider = new TagPersistentVariablesComponentItemProvider(this);
		}

		return tagPersistentVariablesComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.PersistentVar} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected PersistentVarItemProvider persistentVarItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.PersistentVar}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createPersistentVarAdapter() {
		if (persistentVarItemProvider == null) {
			persistentVarItemProvider = new PersistentVarItemProvider(this);
		}

		return persistentVarItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.ReplaceUtfComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ReplaceUtfComponentItemProvider replaceUtfComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.ReplaceUtfComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReplaceUtfComponentAdapter() {
		if (replaceUtfComponentItemProvider == null) {
			replaceUtfComponentItemProvider = new ReplaceUtfComponentItemProvider(this);
		}

		return replaceUtfComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.ReplaceInternalReductionsComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected ReplaceInternalReductionsComponentItemProvider replaceInternalReductionsComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.ReplaceInternalReductionsComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createReplaceInternalReductionsComponentAdapter() {
		if (replaceInternalReductionsComponentItemProvider == null) {
			replaceInternalReductionsComponentItemProvider = new ReplaceInternalReductionsComponentItemProvider(this);
		}

		return replaceInternalReductionsComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.OptimizeConnectivitiesComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected OptimizeConnectivitiesComponentItemProvider optimizeConnectivitiesComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.OptimizeConnectivitiesComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createOptimizeConnectivitiesComponentAdapter() {
		if (optimizeConnectivitiesComponentItemProvider == null) {
			optimizeConnectivitiesComponentItemProvider = new OptimizeConnectivitiesComponentItemProvider(this);
		}

		return optimizeConnectivitiesComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.FillHLTsComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected FillHLTsComponentItemProvider fillHLTsComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.FillHLTsComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createFillHLTsComponentAdapter() {
		if (fillHLTsComponentItemProvider == null) {
			fillHLTsComponentItemProvider = new FillHLTsComponentItemProvider(this);
		}

		return fillHLTsComponentItemProvider;
	}

	/**
	 * This keeps track of the one adapter used for all {@link fr.cea.nabla.nablagen.Ir2CodeComponent} instances.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected Ir2CodeComponentItemProvider ir2CodeComponentItemProvider;

	/**
	 * This creates an adapter for a {@link fr.cea.nabla.nablagen.Ir2CodeComponent}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter createIr2CodeComponentAdapter() {
		if (ir2CodeComponentItemProvider == null) {
			ir2CodeComponentItemProvider = new Ir2CodeComponentItemProvider(this);
		}

		return ir2CodeComponentItemProvider;
	}

	/**
	 * This returns the root adapter factory that contains this factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public ComposeableAdapterFactory getRootAdapterFactory() {
		return parentAdapterFactory == null ? this : parentAdapterFactory.getRootAdapterFactory();
	}

	/**
	 * This sets the composed adapter factory that contains this factory.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void setParentAdapterFactory(ComposedAdapterFactory parentAdapterFactory) {
		this.parentAdapterFactory = parentAdapterFactory;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean isFactoryForType(Object type) {
		return supportedTypes.contains(type) || super.isFactoryForType(type);
	}

	/**
	 * This implementation substitutes the factory itself as the key for the adapter.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Adapter adapt(Notifier notifier, Object type) {
		return super.adapt(notifier, this);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object adapt(Object object, Object type) {
		if (isFactoryForType(type)) {
			Object adapter = super.adapt(object, type);
			if (!(type instanceof Class<?>) || (((Class<?>)type).isInstance(adapter))) {
				return adapter;
			}
		}

		return null;
	}

	/**
	 * This adds a listener.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void addListener(INotifyChangedListener notifyChangedListener) {
		changeNotifier.addListener(notifyChangedListener);
	}

	/**
	 * This removes a listener.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void removeListener(INotifyChangedListener notifyChangedListener) {
		changeNotifier.removeListener(notifyChangedListener);
	}

	/**
	 * This delegates to {@link #changeNotifier} and to {@link #parentAdapterFactory}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void fireNotifyChanged(Notification notification) {
		changeNotifier.fireNotifyChanged(notification);

		if (parentAdapterFactory != null) {
			parentAdapterFactory.fireNotifyChanged(notification);
		}
	}

	/**
	 * This disposes all of the item providers created by this factory. 
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	public void dispose() {
		if (nablagenModuleItemProvider != null) nablagenModuleItemProvider.dispose();
		if (workflowItemProvider != null) workflowItemProvider.dispose();
		if (workflowComponentItemProvider != null) workflowComponentItemProvider.dispose();
		if (childComponentItemProvider != null) childComponentItemProvider.dispose();
		if (ir2IrComponentItemProvider != null) ir2IrComponentItemProvider.dispose();
		if (nabla2IrComponentItemProvider != null) nabla2IrComponentItemProvider.dispose();
		if (tagPersistentVariablesComponentItemProvider != null) tagPersistentVariablesComponentItemProvider.dispose();
		if (persistentVarItemProvider != null) persistentVarItemProvider.dispose();
		if (replaceUtfComponentItemProvider != null) replaceUtfComponentItemProvider.dispose();
		if (replaceInternalReductionsComponentItemProvider != null) replaceInternalReductionsComponentItemProvider.dispose();
		if (optimizeConnectivitiesComponentItemProvider != null) optimizeConnectivitiesComponentItemProvider.dispose();
		if (fillHLTsComponentItemProvider != null) fillHLTsComponentItemProvider.dispose();
		if (ir2CodeComponentItemProvider != null) ir2CodeComponentItemProvider.dispose();
	}

}
